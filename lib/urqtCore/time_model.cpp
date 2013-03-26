
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#pragma implementation
#include "time_model.h"
#include "object.h"
#include "timeouthandler.moc.h"
#include "ruby++/numeric.h"
#include "ruby++/symbol.h"
#include "ruby++/bool.h"
#include "ruby++/hash.h"
#include "ruby++/scan.h"
#include <QtCore/QTimer>

namespace R_Qt {

static RPP::Class
cTimer;

static VALUE
cTimer_alloc(VALUE cTimer)
{
  return RPP::QObject<QTimer>(cTimer, new QTimer);
}

// in ms
static VALUE
cTimer_interval_get(VALUE v_self)
{
  return RPP::Fixnum(RPP::QObject<QTimer>(v_self)->interval());
}

// in ms
static VALUE
cTimer_interval_set(VALUE v_self, VALUE v_interval)
{
  RPP::QObject<QTimer>(v_self)->setInterval(RPP::Fixnum(v_interval));
  return v_interval;
}

static VALUE
cTimer_timerType_get(VALUE v_self)
{
  const RPP::QObject<QTimer> self = v_self;
  switch (self->timerType())
    {
      case Qt::PreciseTimer: return RPP::Symbol("precise");
      case Qt::CoarseTimer: return RPP::Symbol("coarse");
      case Qt::VeryCoarseTimer: return RPP::Symbol("veryCoarse");
    }
  rb_raise(rb_eRuntimeError, "Unhandled timertype %d", self->timerType());
}

static Qt::TimerType
sym2timertype(VALUE v_sym)
{
  RPP::Dictionary types(cTimer.cv("@@types"), RPP::VERYUNSAFE);
  if (!types.isHash())
    {
      types = RPP::Dictionary();
      cTimer.cv_set("@@types", types);
#define TIMERTYPE_DO(sym, qttimertype) \
      types[#sym] = RPP::Fixnum(Qt::qttimertype##Timer)
      TIMERTYPE_DO(default, Coarse);
      TIMERTYPE_DO(coarse, Coarse);
      TIMERTYPE_DO(veryCoarse, VeryCoarse);
      TIMERTYPE_DO(verycoarse, VeryCoarse);
      TIMERTYPE_DO(precise, Precise);
    }
  return Qt::TimerType(RPP::Fixnum(types[v_sym]).to_i());
}

static VALUE
cTimer_timerType_set(VALUE v_self, VALUE v_sym)
{
  RPP::QObject<QTimer>(v_self)->setTimerType(sym2timertype(v_sym));
  return v_sym;
}

static VALUE
cTimer_singleShot_p(VALUE v_self)
{
  return RPP::Bool(RPP::QObject<QTimer>(v_self)->isSingleShot());
}

static VALUE
cTimer_active_p(VALUE v_self)
{
  return RPP::Bool(RPP::QObject<QTimer>(v_self)->isActive());
}

static VALUE
cTimer_singleShot_set(VALUE v_self, VALUE v)
{
  RPP::QObject<QTimer>(v_self)->setSingleShot(RPP::Bool(v));
  return v;
}

/** :call-seq:
 *
 *    Timer.start ms = 0
 */
static VALUE
cTimer_start(int argc, VALUE *argv, VALUE v_self)
{
  RPP::Fixnum ms;
  RPP::Scan(argc, argv).opt(ms);
  const RPP::QObject<QTimer> self = v_self;
  self->start(ms); // ms can be nil, but nil.to_i is 0.
  return v_self;
}

static VALUE
cTimer_stop(VALUE v_self)
{
  RPP::QObject<QTimer>(v_self)->stop();
  return v_self;
}

static VALUE
cTimer_remainingTime(VALUE v_self)
{
  return RPP::Fixnum(RPP::QObject<QTimer>(v_self)->remainingTime());
}

/** :call-seq:
 *
 *    Timer.singleShot ms, receiver, qt-slotname
 *	  calls the given slot on QObject receiver, in about ms milliseconds.
 *    Timer.singleShot ms { puts 'received' }
 *	  calls the block back in about ms milliseconds
 *    Timer.singleShot ms, :timertype, receiver, qt-slot
 *    Timer.singleShot(ms, :timertype) { puts 'received' }
 *
 * The default timertype is :coarse, you may try :verycoarse or :precise
 * The accuracy of :verycoarse is 1000 ms.
 * The accuracy of :coarse is 50 ms.
 * The accuracy of :precise is as close to 0 as possible.
 *
 */
static VALUE
cTimer_singleShot_static(int argc, VALUE *argv, VALUE v_self /* == cTimer*/)
{
  trace("Timer.singleShot");
  VALUE v_ms, v_timertype, v_receiver, v_member, v_block;
  /* Yes, this is not in the pickaxe. But '112' means, 1 lead, 1 opt, and 2 trail. See the source.
  rb_scan_args(argc, argv, "112", &v_ms, &v_timertype, &v_receiver, &v_member);

  At least, if this was usefull.

  But I want this:
	Timer.singleShot(1000) { puts 'Hallo world (a bit delayed)' }
  */
  rb_scan_args(argc, argv, "13&", &v_ms, &v_timertype, &v_receiver, &v_member, &v_block);
  const RPP::Fixnum ms = v_ms;
  RPP::Symbol timertype(v_timertype, RPP::UNSAFE);
  track4("ms = %s, tt = %s, rec = %s, member = %s", ms, timertype, v_receiver,
	 v_member);
  if (!timertype.isSymbol())
    {
      trace("shifting");
      if (!NIL_P(v_member)) rb_raise(rb_eArgError, "bad argument count");
      v_member = v_receiver;
      v_receiver = v_timertype;
      timertype = RPP::Symbol("default");
    }
  track1("v_receiver %s -> receiver", v_receiver);
  const RPP::QObject<QObject> receiver(v_receiver, RPP::UNSAFE); // can be nil
  const RPP::String slot = v_member;
  if (receiver.isNil())
    {
      if (NIL_P(v_block)) rb_raise(rb_eArgError, "no block or slot given");
      /* easily?
       *    QSignalProxy can do this easily, but it creates an instance.
       * We don't want a new proxy each time timeout() is called, so we must delete it
       * when the timeout occurs.
       *
       * I think we should call the Qt delayed delete variant.
       * And we have no 'parent' object. Nor a signal...
       *
       * So it is similar, but not quite the same.
       *
       * 1) let's create a class MyTimeoutHandler: public QObject.
       * 2) it has a method:   handle(). Which is a Qt slot.
       * 3) the constructor receives Proc, and it must be gc-guarded.
       * 4) handle() should execute proc, and then delete itself. Maybe delayed.
       * 5) instantiate it here
       * 6) Pass that object plus the 'handle()' signal
       */
      trace("create QTimeoutHandler");
      QTimeoutHandler * const handler = new QTimeoutHandler(v_block);
      trace("QTimer::singleShot()");
      QTimer::singleShot(ms, sym2timertype(timertype), handler, SLOT(handle())); 
    }
  else
    {
      if (!NIL_P(v_block)) 
	rb_raise(rb_eArgError, "cannot use block together with Qt-slot");
      if (slot.isNil() || slot.isEmpty()) rb_raise(rb_eArgError, "bad slot name");
      trace("QTimer::singleShot()");
      QTimer::singleShot(ms, sym2timertype(timertype), receiver, slot); 
    }
  return v_self;
}

void
init_time_model(RPP::Module qt, RPP::Class cModel)
{
  cTimer = qt.define_class("Timer", cModel);
  cTimer.define_alloc_func(cTimer_alloc)
	.define_method("interval_get", cTimer_interval_get)
	.define_method("interval=", cTimer_interval_set)
	.define_method("timerType_get", cTimer_timerType_get)
	.define_method("timerType=", cTimer_timerType_set)
	.define_method("interval=", cTimer_interval_set)
	.define_method("singleShot?", cTimer_singleShot_p)
	.define_method("active?", cTimer_active_p)
	.define_method("singleShot=", cTimer_singleShot_set)
	.define_method("interval=", cTimer_interval_set)
	.define_method("start", cTimer_start)
	.define_method("stop", cTimer_stop)
	.define_method("remainingTime", cTimer_remainingTime)
	.define_function("singleShot", cTimer_singleShot_static)
	.define_cv("@@types", Qnil)
	;
}


} // namespace R_Qt
