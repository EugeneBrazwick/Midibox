
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#define TRACE

#pragma implementation
#include "graphicsitem.h"
#include "api_utils.h"
#include "object.h"
#include <assert.h>
#include <QtGui/QBrush>

namespace R_Qt {

VALUE 
cRectF = Qnil, cBrush = Qnil, cColor = Qnil, cPen = Qnil;

VALUE
cGraphicsItem = Qnil, cAbstractGraphicsShapeItem = Qnil;

void
cRectF_free(QRectF *rect)
{
  trace1("cRectF_free(%p)", rect);
  traqt1("delete QRectF %p", rect);
  delete rect;
}

void
cBrush_free(QBrush *brush)
{
  traqt1("delete QBrush %p", brush);
  delete brush;
}

static void
cColor_free(QColor *color)
{
  traqt1("delete QColor %p", color);
  delete color;
}

static inline VALUE
cColorWrap(QColor *color)
{
  return Data_Wrap_Struct(cColor, 0, cColor_free, color);
}

R_QT_DEF_ALLOCATOR_BASE1(RectF)
R_QT_DEF_ALLOCATOR_BASE1(Brush)
R_QT_DEF_ALLOCATOR_BASE1(Color)

static void 
init_rect(VALUE mQt)
{
  cRectF = rb_define_class_under(mQt, "Rectangle", rb_cObject);
  rb_define_alloc_func(cRectF, cRectF_alloc);
}

static void 
init_brush(VALUE mQt)
{
  cBrush = rb_define_class_under(mQt, "Brush", cNoQtControl);
  rb_define_alloc_func(cBrush, cBrush_alloc);
  rb_define_const(cBrush, "NoBrush", Qt::NoBrush);
}

static VALUE
cColor_sym2color(VALUE v_self, VALUE v_sym)
{
  VALUE v_colors = rb_iv_get(v_self, "@color");
  if (NIL_P(v_colors))
    {
      v_colors = rb_hash_new();
      rb_iv_set(v_self, "@color", v_colors);
#define QTCOLOR_DO(sym) \
      rb_hash_aset(v_colors, CSTR2SYM(#sym), INT2NUM(Qt::sym))
      QTCOLOR_DO(white);
      QTCOLOR_DO(black);
      QTCOLOR_DO(yellow);
      QTCOLOR_DO(blue);
      QTCOLOR_DO(green);
      QTCOLOR_DO(red);
      QTCOLOR_DO(darkYellow);
      QTCOLOR_DO(darkBlue);
      QTCOLOR_DO(darkGreen);
      QTCOLOR_DO(darkRed);
      QTCOLOR_DO(cyan);
      QTCOLOR_DO(darkCyan);
      QTCOLOR_DO(magenta);
      QTCOLOR_DO(darkMagenta);
      QTCOLOR_DO(gray);
      QTCOLOR_DO(darkGray);
      QTCOLOR_DO(lightGray);
      QTCOLOR_DO(transparent);
    }
  Check_Type(T_HASH, v_colors);
  return rb_hash_aref(v_colors, v_sym);
}

// where hex is in range '0'..'9' or 'A'..'F'
static inline int
hex2int(int hex)
{
  return hex - (hex >= 'A' ? 'A' - 10 : '0');
}

/** :call-seq:
    Color.new :white					   # or any other QGlobalColor. These are cached.
    Color.new Color
    Color.new Color, alpha
    Color.new Brush
    Color.new '#rgb'					    # must be hexadecimals, case insensitive
    Color.new '#rrggbb'
    Color.new '#rrrgggbbb'
    Color.new '#rrrrggggbbbb'
    Color.new '#rgba'					    # etc
    Color.new red, green, blue, opaqueness = 255	    # all values must be between 0 and 255
    Color.new gray_value, opaqueness = 255  
    Color.new red, green, blue, opaqueness = 1.0	    # all values must be between 0.0 and 1.0
    Color.new gray_value, opaqueness = 1.0  
    Color.new [array_args]				    # splatted
    Color.new Hash					    # same as Control constructor
    Color.new { initblock }				    # same as Control constructor

    Colors have neither parents nor children
 */
static VALUE
cColor_initialize(int argc, VALUE *argv, VALUE v_self)
{
  RQTDECLARE_COLOR(self);
  VALUE v_colorsym, v_g, v_b, v_a;
  rb_scan_args(argc, argv, "13", &v_colorsym, &v_g, &v_b, &v_a);
  track4("cColor_initialize(%s, %s, %s, %s)", v_colorsym, v_g, v_b, v_a);
  switch (TYPE(v_colorsym))
    {
    case T_DATA:
	if (rb_obj_is_kind_of(v_colorsym, cColor)) 
	  {
	    if (!NIL_P(v_g))
	      rb_funcall(v_colorsym, rb_intern("alpha="), 1, v_g);
	    return v_colorsym;
	  }
	if (rb_obj_is_kind_of(v_colorsym, cBrush))
	  return rb_funcall(v_colorsym, rb_intern("color"), 0);
	break;
    case T_STRING:
      {
	char *s = StringValueCStr(v_colorsym);
	if (*s == '#')
	  {
	    const size_t l = strlen(s);
	    char t[l + 1];
	    strcpy(t, s);
	    s = t;
	    for (char *t = s; *t; t++)
	      *t = toupper(*t);
	    switch (l)
	      {
	      case 5:
		{
		  // 17 * 0xf = 17 * 15 = 255. How nice.
		  const int alpha = hex2int(s[4]) * 17;
		  s[4] = 0;
		  QColor * const r = new QColor(s);
		  r->setAlpha(alpha);
		  return cColorWrap(r);
		}
	      case 9:
		{
		  const int alpha = hex2int(s[7]) * 16 + hex2int(s[8]);
		  s[7] = 0;
		  QColor * const r = new QColor(s);
		  r->setAlpha(alpha);
		  return cColorWrap(r);
		}
	      case 13:
		{
		  const int alpha = hex2int(s[10]) * 256 + hex2int(s[11]) * 16 + hex2int(s[12]);
		  s[10] = 0;
		  QColor * const r = new QColor(s);
		  r->setAlphaF(alpha / 4096.0);
		  return cColorWrap(r);
		}
	      case 17:
		{
		  const int alpha = hex2int(s[13]) * 65536 + hex2int(s[14]) * 256 
				    + hex2int(s[15]) * 16 + hex2int(s[16]);
		  s[13] = 0;
		  QColor * const r = new QColor(s);
		  r->setAlphaF(alpha / 65536.0);
		  return cColorWrap(r);
		}
	      default:
		  break;
	      } // switch strlen
	    return cColorWrap(new QColor(s));
	  } // strings starting with '#'
	// ordinary string
	return cColorWrap(new QColor(s));
      }
    case T_ARRAY:
	return cColor_initialize(RARRAY_LEN(v_colorsym), RARRAY_PTR(v_colorsym), v_self);
    case T_FIXNUM:
      {
	if (NIL_P(v_b))
	  {
	    const int gray = NUM2INT(v_colorsym);
	    const int alpha = NIL_P(v_g) ? 255 : NUM2INT(v_g);
	    return cColorWrap(new QColor(gray, gray, gray, alpha));
	  }
	const int alpha = NIL_P(v_a) ? 255 : NUM2INT(v_a);
	return cColorWrap(new QColor(NUM2INT(v_colorsym), NUM2INT(v_g), NUM2INT(v_b), alpha));
      }
    case T_FLOAT:
      {
	if (NIL_P(v_b))
	  {
	    const double gray = NUM2DBL(v_colorsym);
	    const double alpha = NIL_P(v_g) ? 1.0 : NUM2DBL(v_g);
	    return cColorWrap(new QColor(gray, gray, gray, alpha));
	  }
	const double alpha = NIL_P(v_a) ? 1.0 : NUM2DBL(v_a);
	return cColorWrap(new QColor(NUM2DBL(v_colorsym), NUM2DBL(v_g), NUM2DBL(v_b), alpha));
      }
    case T_SYMBOL:
	return cColor_sym2color(cColor, v_colorsym);
    } // switch TYPE v_colorsym
  rb_raise(rb_eArgError, "invalid color %s, %s, %s, %s", INSPECT(v_colorsym), INSPECT(v_g),
	   INSPECT(v_b), INSPECT(v_a));
} // cColor_initialize

static void 
init_color(VALUE mQt)
{
  trace("init_color");
  cColor = rb_define_class_under(mQt, "Color", cNoQtControl);
  rb_define_alloc_func(cColor, cColor_alloc);
  rb_define_module_function(cColor, "sym2color", RUBY_METHOD_FUNC(cColor_sym2color), 1);
  rb_define_private_method(cColor, "initialize", RUBY_METHOD_FUNC(cColor_initialize), -1);
  trace("DONE init_color");
}

void 
cGraphicsItem_mark(QGraphicsItem *item)
{
  if (!item) return;
  foreach (QGraphicsItem *child, item->childItems())
    {
      const VALUE v_child = item2v(child);
      if (!NIL_P(v_child))
	rb_gc_mark(v_child);
    }
  for (int i = 0; i < R_QT_GI_KEY_COUNT; i++)
    {
      traqt1("QGraphicsItem::data(%d)", i);
      const QVariant &var = item->data(i);
      assert(var.canConvert<RValue>());
      rb_gc_mark(var.value<RValue>());
    }
} // cGraphicsItem_mark

#if defined(DEBUG)
VALUE item2v(QGraphicsItem *i)
{
  if (!i) return Qnil;
  trace1("item2v(%p)", i);
  const QVariant &rvalue = i->data(R_QT_INTERNAL_GI_KEY);
  if (!rvalue.isValid()) return Qnil;
  const RValue &rv = rvalue.value<RValue>();
  trace2("item2v(%p) -> rv %p", i, &rv);
  trace2("item2v(%p) -> VALUE = %p", i, (void *)rv.v());
  trace2("item2v(%p) -> INSPECT -> %s", i, INSPECT(rv)); 
  return rv; 
}
#endif // DEBUG

static void
zombify(QGraphicsItem *item)
{
  const VALUE v_item = item2v(item);
  if (!NIL_P(v_item))
    {
      trace("zombify child");
      ZOMBIFY(v_item);
    }
  traqt("QGraphicsItem::childItems");
  const QList<QGraphicsItem*> &children = item->childItems();
  foreach (QGraphicsItem *child, children) 
    zombify(child);
}

// NOTICE: do NOT call super here!!
static VALUE
cGraphicsItem_initialize(int argc, VALUE *argv, VALUE v_self)
{
#if defined(DEBUG)
  QGraphicsItem * const self = 
#endif
			       v2item(v_self); // First mark ownership
#if defined(DEBUG)
  const VALUE vdbg = item2v(self);
  assert(vdbg == v_self);
#endif
  //trace("scan args and assign parent");
  VALUE v_0, v_1, v_2;
  rb_scan_args(argc, argv, "03", &v_0, &v_1, &v_2);
  if (!NIL_P(v_0))
    {
      cObject_initialize_arg(v_self, v_0);
      if (!NIL_P(v_1))
	{
	  cObject_initialize_arg(v_self, v_1);
	  if (!NIL_P(v_2))
	    cObject_initialize_arg(v_self, v_2);
	}
    }
  if (rb_block_given_p())
    rb_obj_instance_eval(0, 0, v_self);
  return Qnil;
}

static void 
cGraphicsItem_delete(VALUE v_self)
{
  if (IS_ZOMBIFIED(v_self)) return;
  RQTDECLSELF_GI(QGraphicsItem);
  zombify(self);
  traqt1("delete QGraphicsItem(%p)", self);
  delete self;
}

static VALUE 
cGraphicsItem_parent_set(VALUE v_self, VALUE v_parent)
{
  trace("cGraphicsItem_parent_set");
  rb_check_frozen(v_self);
  QGraphicsItem *parent = 0;
  if (!NIL_P(v_parent))
    GET_STRUCT_NODECL(QGraphicsItem, parent);
  trace("retrieve self");
  RQTDECLSELF_GI(QGraphicsItem);
  traqt("QGraphicsItem::setParentItem");
  self->setParentItem(parent);
  return v_parent;
}

static VALUE
cGraphicsItem_objectName_set(VALUE v_self, VALUE v_newname)
{
  rb_check_frozen(v_self);
  RQTDECLSELF_GI(QGraphicsItem);
  traqt("QGraphicsItem::setData");
  self->setData(R_QT_NAME_GI_KEY, QVariant::fromValue(RValue(v_newname)));
  return v_newname;
}

static VALUE
cGraphicsItem_objectName_get(VALUE v_self)
{
  RQTDECLSELF_GI(QGraphicsItem);
  const QVariant &var = self->data(R_QT_NAME_GI_KEY);
  return *var.value<RValue>();
}

static VALUE
cGraphicsItem_parent(int argc, VALUE *argv, VALUE v_self)
{
  trace("cObject_parent");
  RQTDECLSELF_GI(QGraphicsItem);
  if (argc == 0) 
    {
      traqt("QGraphicsItem::parentItem");
      return item2v(self->parentItem());
    }
  VALUE v_new_parent;
  rb_scan_args(argc, argv, "1", &v_new_parent);
  return cGraphicsItem_parent_set(v_self, v_new_parent);
}

static VALUE
cGraphicsItem_each_sub(VALUE v_self)
{
  trace1("%s::each_sub", TO_CSTR(v_self));
  RETURN_ENUMERATOR(v_self, 0, 0);
  RQTDECLSELF_GI(QGraphicsItem);
  VALUE v_queue = rb_ary_new();
  trace("calling enqueue_children");
  // do NOT pass block. We use the 'fillqueue' variant
  rb_funcall(v_self, rb_intern("enqueue_children"), 1, v_queue);
  while (RARRAY_LEN(v_queue))
    {
      VALUE v_node = rb_ary_shift(v_queue);
      track2("%s::each_sub, dequeued %s", v_self, v_node);
      QGraphicsItem *node;
      Data_Get_Struct(v_node, QGraphicsItem, node);
      const VALUE v_truenode = item2v(node);
      if (!NIL_P(v_truenode))
	{
	  rb_yield(v_truenode);
	  v_node = v_truenode; // otherwise cObject_enqueue_children is always called...
	}
      rb_funcall(v_node, rb_intern("enqueue_children"), 1, v_queue);
    }
  trace1("DONE %s::each_sub", TO_CSTR(v_self));
  return Qnil;
} // cObject_each_sub

static VALUE 
cGraphicsItem_enqueue_children(VALUE v_self, VALUE v_queue)
{
  trace("cGraphicsItem_enqueue_children");
  track2("%s::enqueue_children(%s)", v_self, v_queue);
  RQTDECLSELF_GI(QGraphicsItem);
  traqt1("%s::childItems", QTCLASS(self));
  const QList<QGraphicsItem*> &children = self->childItems();
  trace1("#children = %d", children.count());
  const bool yield = NIL_P(v_queue);
  foreach (QGraphicsItem *child, children)
    {
      const VALUE v_child = item2v(child);
      if (yield)
	{
	  if (!NIL_P(v_child)) 
	    rb_yield(v_child);
	}
      else
	{
	  Check_Type(v_queue, T_ARRAY);
	  if (NIL_P(v_child)) 
	    rb_ary_push(v_queue, Data_Wrap_Struct(cGraphicsItem, 0, 0, child));
	  else
	    rb_ary_push(v_queue, v_child);
	}
    }
  return Qnil;
}

static VALUE
cGraphicsItem_connect(VALUE /*v_self*/, VALUE v_signal, VALUE v_proc)
{
  if (TYPE(v_signal) != T_SYMBOL) rb_raise(rb_eTypeError, "GraphicItems only support ruby signals");
  VALUE v_args[2] = { v_signal, v_proc };
  return rb_call_super(2, v_args);
}

static VALUE
cGraphicsItem_emit(int argc, VALUE *argv, VALUE /*v_self*/)
{
  VALUE v_signal, v_args;
  rb_scan_args(argc, argv, "1*", &v_signal, &v_args);
  if (TYPE(v_signal) != T_SYMBOL) rb_raise(rb_eTypeError, "GraphicItems only support ruby signals");
  return rb_call_super(argc, argv);
}

static VALUE
cAbstractGraphicsShapeItem_brush_set(VALUE v_self, VALUE v_brush)
{
  RQTDECLSELF_GI(QAbstractGraphicsShapeItem);
  RQTDECLARE_BRUSH(brush);
  self->setBrush(*brush);
  return v_brush;
}

static VALUE
cAbstractGraphicsShapeItem_brush_get(VALUE v_self)
{
  RQTDECLSELF_GI(QAbstractGraphicsShapeItem);
  return cBrushWrap(new QBrush(self->brush()));
}

VALUE
init_graphicsitem(VALUE mQt, VALUE /*cControl*/)
{
  init_rect(mQt);
  init_brush(mQt);
  init_color(mQt);
  cGraphicsItem = rb_define_class_under(mQt, "GraphicsItem", cNoQtControl);
  rb_define_private_method(cGraphicsItem, "initialize", RUBY_METHOD_FUNC(cGraphicsItem_initialize), -1);
  rb_define_method(cGraphicsItem, "delete", RUBY_METHOD_FUNC(cGraphicsItem_delete), 0);
  rb_define_method(cGraphicsItem, "parent", RUBY_METHOD_FUNC(cGraphicsItem_parent), -1);
  rb_define_method(cGraphicsItem, "parent=", RUBY_METHOD_FUNC(cGraphicsItem_parent_set), 1);
  rb_define_method(cGraphicsItem, "enqueue_children", RUBY_METHOD_FUNC(cGraphicsItem_enqueue_children), 1);
  rb_define_method(cGraphicsItem, "objectName_get", RUBY_METHOD_FUNC(cGraphicsItem_objectName_get), 0);
  rb_define_method(cGraphicsItem, "objectName=", RUBY_METHOD_FUNC(cGraphicsItem_objectName_set), 1);
  rb_define_method(cGraphicsItem, "delete", RUBY_METHOD_FUNC(cGraphicsItem_delete), 0);
  rb_define_method(cGraphicsItem, "each_sub", RUBY_METHOD_FUNC(cGraphicsItem_each_sub), 0);
  rb_define_private_method(cGraphicsItem, "connect", RUBY_METHOD_FUNC(cGraphicsItem_connect), 2);
  rb_define_private_method(cGraphicsItem, "emit", RUBY_METHOD_FUNC(cGraphicsItem_emit), -1);
  cAbstractGraphicsShapeItem = rb_define_class_under(mQt, "AbstractGraphicsShapeItem", cGraphicsItem);
  rb_define_method(cAbstractGraphicsShapeItem, "brush=", RUBY_METHOD_FUNC(cAbstractGraphicsShapeItem_brush_set), 1);
  rb_define_method(cAbstractGraphicsShapeItem, "brush_get", RUBY_METHOD_FUNC(cAbstractGraphicsShapeItem_brush_get), 0);
  return cGraphicsItem;
};

} // namespace R_Qt 
