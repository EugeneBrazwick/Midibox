
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#pragma implementation
#include "animation.h"
#include "object.h"
#include <QtCore/QPropertyAnimation>
#include "ruby++/symbol.h"
#include "ruby++/scan.h"
#include "ruby++/bool.h"

namespace R_Qt {
RPP::Class 
cEasingCurve;

static inline void
cEasingCurve_free(QEasingCurve *easing)
{
  delete easing;
}

} // namespace R_Qt 

namespace RPP {
class QEasingCurve: public DataObject< ::QEasingCurve >
{
private:
  typedef DataObject< ::QEasingCurve > inherited;
public:
  QEasingCurve(VALUE v_ec, E_SAFETY safe = SAFE): 
    inherited(v_ec, R_Qt::cEasingCurve, safe) 
    {
    }
  QEasingCurve(::QEasingCurve *easing): 
    inherited(Data_Wrap_Struct(R_Qt::cEasingCurve, 0, R_Qt::cEasingCurve_free, easing), easing) 
    {
    }
  QEasingCurve(const ::QEasingCurve &easing): QEasingCurve(new ::QEasingCurve(easing)) {}
  void operator=(VALUE v) { V = v; }
}; // class QEasingCurve

} // namespace RPP

namespace R_Qt {

static VALUE
cEasingCurve_alloc(VALUE /*cEasingCurve*/)
{
  return RPP::QEasingCurve(new QEasingCurve);
}

// duration in milliseconds
static VALUE
cAbstractAnimation_duration_get(VALUE v_self)
{
  return RPP::Fixnum(RPP::QObject<QAbstractAnimation>(v_self)->duration());
}

static VALUE
cAbstractAnimation_totalDuration(VALUE v_self)
{
  return RPP::Fixnum(RPP::QObject<QAbstractAnimation>(v_self)->totalDuration());
}

static VALUE
cAbstractAnimation_loopCount_get(VALUE v_self)
{
  return RPP::Fixnum(RPP::QObject<QAbstractAnimation>(v_self)->loopCount());
}

static VALUE
cAbstractAnimation_loopCount_set(VALUE v_self, VALUE v_dur)
{
  RPP::QObject<QAbstractAnimation>(v_self)->setLoopCount(RPP::Fixnum(v_dur));
  return v_self;
}

static VALUE
cAbstractAnimation_currentLoop(VALUE v_self)
{
  return RPP::Fixnum(RPP::QObject<QAbstractAnimation>(v_self)->currentLoop());
}

// relative time in milliseconds since last loop started
static VALUE
cAbstractAnimation_currentLoopTime(VALUE v_self)
{
  return RPP::Fixnum(RPP::QObject<QAbstractAnimation>(v_self)->currentLoopTime());
}

static VALUE
cAbstractAnimation_currentTime_get(VALUE v_self)
{
  return RPP::Fixnum(RPP::QObject<QAbstractAnimation>(v_self)->currentTime());
}

static VALUE
cAbstractAnimation_currentTime_set(VALUE v_self, VALUE v_time)
{
  RPP::QObject<QAbstractAnimation>(v_self)->setCurrentTime(RPP::Fixnum(v_time));
  return v_self;
}

RPP::Symbol
QAbstractAnimation_State2Symbol(QAbstractAnimation::State state)
{
  switch (state)
    {
    case QAbstractAnimation::Stopped: return RPP::Symbol("stopped");
    case QAbstractAnimation::Paused: return RPP::Symbol("paused");
    case QAbstractAnimation::Running: return RPP::Symbol("running");
    }
  rb_raise(rb_eRuntimeError, "QAbstractAnimation_State2Symbol: unhandled state %d", state);
}

static VALUE
cAbstractAnimation_state(VALUE v_self)
{
  const RPP::QObject<QAbstractAnimation>self = v_self;
  return QAbstractAnimation_State2Symbol(self->state());
}

static VALUE
cAbstractAnimation_direction_get(VALUE v_self)
{
  const QAbstractAnimation::Direction d = RPP::QObject<QAbstractAnimation>(v_self)->direction();
  switch (d)
    {
    case QAbstractAnimation::Forward: return RPP::Symbol("forward");
    case QAbstractAnimation::Backward: return RPP::Symbol("backward");
    }
  rb_raise(rb_eRuntimeError, "unknown direction %d", d);
}

static VALUE
cAbstractAnimation_direction_set(VALUE v_self, VALUE v_dir)
{
  const RPP::Symbol dir = v_dir;
  const QAbstractAnimation::Direction d = dir == "forward" ? QAbstractAnimation::Forward
							   : QAbstractAnimation::Backward;
  if (d == QAbstractAnimation::Backward && dir != "backward")
    rb_raise(rb_eArgError, "bad direction :%s", dir.to_s());
  RPP::QObject<QAbstractAnimation>(v_self)->setDirection(d);
  return v_self;
}

static VALUE
cAbstractAnimation_start(int argc, VALUE *argv, VALUE v_self)
{
  track1("%s::start", v_self);
  RPP::Symbol policy(RPP::UNSAFE);
  RPP::Scan(argc, argv).opt(policy);
  QAbstractAnimation::DeletionPolicy pol = QAbstractAnimation::KeepWhenStopped;
  if (policy.test())
    {
      if (policy == "keepWhenStopped"
	  || policy == "default"
	  || policy == "keep" )
	pol = QAbstractAnimation::KeepWhenStopped;
      else if (policy == "deleteWhenStopped"
	       || policy == "autoDelete"
	       || policy == "auto_delete"
	       )
	pol = QAbstractAnimation::DeleteWhenStopped;
      else 
	rb_raise(rb_eArgError, "bad DeletionPolicy :%s", policy.to_s());
    }
  RPP::QObject<QAbstractAnimation>(v_self)->start(pol);
  return v_self;
}

static VALUE
cAbstractAnimation_stop(VALUE v_self)
{
  RPP::QObject<QAbstractAnimation>(v_self)->stop();
  return v_self;
}

static VALUE
cAbstractAnimation_pause(VALUE v_self)
{
  RPP::QObject<QAbstractAnimation>(v_self)->pause();
  return v_self;
}

static VALUE
cAbstractAnimation_resume(VALUE v_self)
{
  RPP::QObject<QAbstractAnimation>(v_self)->resume();
  return v_self;
}

static VALUE
cAbstractAnimation_paused_set(VALUE v_self, VALUE v_on)
{
  RPP::QObject<QAbstractAnimation>(v_self)->setPaused(RPP::Bool(v_on));
  return v_self;
}

// Not in Qt. returns true unless state == :running
static VALUE
cAbstractAnimation_paused_get(VALUE v_self)
{
  const QAbstractAnimation::State s = RPP::QObject<QAbstractAnimation>(v_self)->state();
  return RPP::Bool(s != QAbstractAnimation::Running);
}

static VALUE
cAbstractAnimation_running_get(VALUE v_self)
{
  const QAbstractAnimation::State s = RPP::QObject<QAbstractAnimation>(v_self)->state();
  return RPP::Bool(s == QAbstractAnimation::Running);
}

static VALUE
cVariantAnimation_easingCurve_set(VALUE v_self, VALUE v_easing)
{
  const RPP::QObject<QVariantAnimation> self = v_self;
  const RPP::QEasingCurve easing(v_easing, RPP::UNSAFE);
  if (easing.isNil())
    self->setEasingCurve(QEasingCurve());
  else
    self->setEasingCurve(*easing);
  return v_easing;
}

static VALUE
cVariantAnimation_easingCurve_get(VALUE v_self)
{
  const RPP::QObject<QVariantAnimation> self = v_self;
  return RPP::QEasingCurve(self->easingCurve()); 
}

static VALUE
cVariantAnimation_startValue_set(VALUE v_self, VALUE v_start)
{
  track2("%s::startValue=%s", v_self, v_start);
  const RPP::QObject<QVariantAnimation> self = v_self;
  const QVariant qv = v2qvar_safe(v_start);
  trace("calling setStartValue");
  self->setStartValue(qv);
  trace("DONE");
  return v_self;
}

static VALUE
cVariantAnimation_startValue(int argc, VALUE *argv, VALUE v_self)
{
  trace2("%s::startValue, argc=%d", INSPECT(v_self), argc);
  RPP::Object value;
  RPP::Scan(argc, argv).opt(value);
  const RPP::QObject<QVariantAnimation> self = v_self;
  if (value.test())
    /* BAD IDEA not polymorf
    return cVariantAnimation_startValue_set(v_self, value);
    */
    return self.call("startValue=", value);
  return qvar2v_safe(self->startValue());
}

// The default is 250(ms)
static VALUE
cVariantAnimation_duration_set(VALUE v_self, VALUE v_dur)
{
  RPP::QObject<QVariantAnimation>(v_self)->setDuration(RPP::Fixnum(v_dur));
  return v_self;
}

static VALUE
cVariantAnimation_endValue_set(VALUE v_self, VALUE v_end)
{
  trace("endValue_set");
  const RPP::QObject<QVariantAnimation> self = v_self;
  const RPP::QObject<QObject> parent = self->parent(); 
  const QVariant var = v2qvar_safe(v_end);
  self->setEndValue(var);
  return v_self;
}

static VALUE
cVariantAnimation_endValue(int argc, VALUE *argv, VALUE v_self)
{
  RPP::Object value;
  RPP::Scan(argc, argv).opt(value);
  if (value.test())
    return cVariantAnimation_endValue_set(v_self, value);
  const RPP::QObject<QVariantAnimation> self = v_self;
  return qvar2v_safe(self->endValue());
}

static VALUE
cPropertyAnimation_alloc(VALUE cPropertyAnimation)
{
  return RPP::QObject<QPropertyAnimation>(cPropertyAnimation, new QPropertyAnimation);
}

       /*    target.dynamicPropertyChanged do |name|
       *      val = property(name)
       *      apply_model val
       *    end
       */
static VALUE
dynamicPropertyChanged_block(VALUE v_name, VALUE v_self)
{
  trace("{ dynamicPropertyChanged }");
  const RPP::QObject<QObject> self = v_self;
  const QVariant var = self->property(RPP::String(v_name));
  self.call("apply_model", qvar2v_safe(var));
  return Qnil;
}

/* override */
static VALUE
cPropertyAnimation_startValue_set(VALUE v_self, VALUE v_start)
{
  track2("%s::startValue=%s", v_self, v_start);
  const RPP::QObject<QPropertyAnimation> self = v_self;
  /* If no target is set here, use parent.
   * If no propertyName is set here, use R_QT_DYNVALUE_PROPERTYID.
   * This assumes the parent can only have 1 animation at a time.
   * But it auto updates the value inside the parent!
   * Which I expect to be a DynamicAttribute anyway!
   */
  if (!self->targetObject())
    {
      const RPP::QObject<QObject> parent = self->parent(); 
      track1("no target, use parent %s", parent);
      self->setTargetObject(parent);
      /* Normally that would be the DynamicAttribute.
       *
       * It is now important that the handler is set.
       * Something like:
       *
       *    target.disconnect :dynamicPropertyChanged
       *    target.dynamicPropertyChanged do |name|
       *      val = property(name)
       *      apply_model val
       *    end
       *
       * And now in C++...
       */
      parent.call("disconnect", RPP::Symbol("dynamicPropertyChanged"));
      /* CONFUSING.
       * disconnect is NOT required at the moment, since
       * dynamicPropertyChanged is a ruby-signal and there can only be one 'slot' currently.
       */
      parent.call_with_block("dynamicPropertyChanged", dynamicPropertyChanged_block, parent);
    }
  if (self->propertyName().isEmpty())
    {
      const QVariant var = v2qvar_safe(v_start);
      const RPP::QObject<QObject> parent = self->parent(); 
      parent->setProperty(R_QT_DYNVALUE_PROPERTYID, var);
      trace("no propertyName set, use DYNVALUE magic");
      self->setPropertyName(QByteArray(R_QT_DYNVALUE_PROPERTYID));
    }
  return self.super(v_start); 
}

static VALUE
cPropertyAnimation_targetObject_set(VALUE v_self, VALUE v_obj)
{
  RPP::QObject<QPropertyAnimation>(v_self)->setTargetObject(RPP::QObject<QObject>(v_obj));
  return v_self;
}

static VALUE
cPropertyAnimation_targetObject(int argc, VALUE *argv, VALUE v_self)
{
  RPP::Object value;
  RPP::Scan(argc, argv).opt(value);
  if (value.test()) return cPropertyAnimation_targetObject_set(v_self, value);
  return RPP::QObject<QObject>(RPP::QObject<QPropertyAnimation>(v_self)->targetObject());
}

static VALUE
cPropertyAnimation_propertyName_set(VALUE v_self, VALUE v_name)
{
  RPP::QObject<QPropertyAnimation>(v_self)->setPropertyName(v2QByteArray(v_name));
  return v_self;
}

static VALUE
cPropertyAnimation_propertyName(int argc, VALUE *argv, VALUE v_self)
{
  RPP::Object value;
  RPP::Scan(argc, argv).opt(value);
  if (value.test()) return cPropertyAnimation_propertyName_set(v_self, value);
  return qByteArray2v(RPP::QObject<QPropertyAnimation>(v_self)->propertyName());
}

void
init_animation(RPP::Module mQt, RPP::Class cControl)
{
  cEasingCurve = mQt.define_class("EasingCurve", cNoQtControl);
  cEasingCurve.define_alloc_func(cEasingCurve_alloc);
  const RPP::Class cAbstractAnimation = mQt.define_class("AbstractAnimation", 
							 cControl);
  cAbstractAnimation.define_method("duration_get", cAbstractAnimation_duration_get)
		    .define_method("loopCount=", cAbstractAnimation_loopCount_set)
		    .define_method("loopCount_get", cAbstractAnimation_loopCount_get)
		    .define_method("currentLoop", cAbstractAnimation_currentLoop)
		    .define_method("currentLoopTime", cAbstractAnimation_currentLoopTime)
		    .define_method("currentTime=", cAbstractAnimation_currentTime_set)
		    .define_method("currentTime_get", cAbstractAnimation_currentTime_get)
		    .define_method("state", cAbstractAnimation_state)
		    .define_method("direction=", cAbstractAnimation_direction_set)
		    .define_method("direction_get", cAbstractAnimation_direction_get)
		    .define_method("totalDuration", cAbstractAnimation_totalDuration)
		    .define_method("start", cAbstractAnimation_start)
		    .define_method("stop", cAbstractAnimation_stop)
		    .define_method("pause", cAbstractAnimation_pause)
		    .define_method("resume", cAbstractAnimation_resume)
		    .define_method("paused=", cAbstractAnimation_paused_set)
		    .define_method("paused_get", cAbstractAnimation_paused_get)
		    .define_method("running?", cAbstractAnimation_running_get)
		    ;
  const RPP::Class cVariantAnimation = mQt.define_class("VariantAnimation", 
							cAbstractAnimation);
  // It does not seem very usefull to make these dynamic 
  cVariantAnimation.define_method("startValue=", cVariantAnimation_startValue_set);
  cVariantAnimation.define_method("startValue", cVariantAnimation_startValue);
  cVariantAnimation.define_method("endValue=", cVariantAnimation_endValue_set);
  cVariantAnimation.define_method("endValue", cVariantAnimation_endValue);
  cVariantAnimation.define_method("duration=", cVariantAnimation_duration_set);
  cVariantAnimation.define_method("easingCurve=", cVariantAnimation_easingCurve_set);
  cVariantAnimation.define_method("easingCurve_get", cVariantAnimation_easingCurve_get);
  const RPP::Class cPropertyAnimation = mQt.define_class("PropertyAnimation", 
							 cVariantAnimation);
  cPropertyAnimation.define_alloc_func(cPropertyAnimation_alloc)
		    .define_method("targetObject=", cPropertyAnimation_targetObject_set)
		    .define_method("targetObject", cPropertyAnimation_targetObject)
		    .define_method("propertyName=", cPropertyAnimation_propertyName_set)
		    .define_method("propertyName", cPropertyAnimation_propertyName)
		    .define_method("startValue=", cPropertyAnimation_startValue_set)
		    ;
}

} // namespace R_Qt


