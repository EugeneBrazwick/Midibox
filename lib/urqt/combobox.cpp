
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#include <QtWidgets/QComboBox>
#include "application.h"
#include "color.h"
#include "urqtCore/size.h"
#include "urqtCore/rvalue.h"
#include "ruby++/rppstring.h"
#include "ruby++/bool.h"
#include "ruby++/numeric.h"

namespace R_Qt {

static VALUE
cComboBox_alloc(VALUE cComboBox)
{
  return RPP::QObject<QComboBox>(cComboBox, new QComboBox);
}

static VALUE
cComboBox_count(VALUE v_self)
{
  return RPP::Fixnum(RPP::QObject<QComboBox>(v_self)->count());
}

static VALUE
cComboBox_maxCount_get(VALUE v_self)
{
  return RPP::Fixnum(RPP::QObject<QComboBox>(v_self)->maxCount());
}

static VALUE
cComboBox_maxCount_set(VALUE v_self, VALUE v_max)
{
  const RPP::QObject<QComboBox> self = v_self;
  self.check_frozen();
  self->setMaxCount(RPP::Fixnum(v_max));
  return v_max;
}

static VALUE cComboBox_minimumContentsLength_get(VALUE v_self)
{
  return RPP::Fixnum(RPP::QObject<QComboBox>(v_self)->minimumContentsLength());
}

static VALUE
cComboBox_minimumContentsLength_set(VALUE v_self, VALUE v_max)
{
  const RPP::QObject<QComboBox> self = v_self;
  self.check_frozen();
  self->setMinimumContentsLength(RPP::Fixnum(v_max));
  return v_max;
}

static VALUE
cComboBox_maxVisibleItems_get(VALUE v_self)
{
  return RPP::Fixnum(RPP::QObject<QComboBox>(v_self)->maxVisibleItems());
}

static VALUE
cComboBox_maxVisibleItems_set(VALUE v_self, VALUE v_max)
{
  const RPP::QObject<QComboBox> self = v_self;
  self.check_frozen();
  self->setMaxVisibleItems(RPP::Fixnum(v_max));
  return v_max;
}

static VALUE
cComboBox_currentIndex_get(VALUE v_self)
{
  return RPP::Fixnum(RPP::QObject<QComboBox>(v_self)->currentIndex());
}

static VALUE
cComboBox_currentIndex_set(VALUE v_self, VALUE v_idx)
{
  const RPP::QObject<QComboBox> self = v_self;
  self.check_frozen();
  self->setCurrentIndex(RPP::Fixnum(v_idx));
  return v_idx;
}

static VALUE
cComboBox_currentText_get(VALUE v_self)
{
  return qString2v(RPP::QObject<QComboBox>(v_self)->currentText());
}

static VALUE
cComboBox_currentText_set(VALUE v_self, VALUE v_text)
{
  const RPP::QObject<QComboBox> self = v_self;
  self.check_frozen();
  self->setCurrentText(RPP::String(v_text).to_s());
  return v_text;
}

static VALUE
cComboBox_editable_p(VALUE v_self)
{
  return RPP::Bool(RPP::QObject<QComboBox>(v_self)->isEditable());
}

static VALUE
cComboBox_editable_set(VALUE v_self, VALUE v)
{
  RPP::QObject<QComboBox>(v_self)->setEditable(RPP::Bool(v));
  return v;
}

static VALUE
cComboBox_frame_p(VALUE v_self)
{
  return RPP::Bool(RPP::QObject<QComboBox>(v_self)->hasFrame());
}

static VALUE
cComboBox_frame_set(VALUE v_self, VALUE v)
{
  RPP::QObject<QComboBox>(v_self)->setFrame(RPP::Bool(v));
  return v;
}

static VALUE
cComboBox_iconSize_get(VALUE v_self)
{
  return RPP::QSize(RPP::QObject<QComboBox>(v_self)->iconSize());
}

static VALUE
cComboBox_iconSize_set(int argc, VALUE *argv, VALUE v_self)
{
  const RPP::QObject<QComboBox> self = v_self;
  self.check_frozen();
  self->setIconSize(RPP::QSize(argc, argv));
  return v_self;
}

#define R_QT_MODEL_PROPERTYID R_QT_INTERNAL_PROPERTY_PREFIX "model"

class CBModel: public QAbstractListModel
{
private:
  typedef QAbstractListModel inherited;
  QComboBox &Owner;
  const RPP::Object View, Model;
public:
  CBModel(QComboBox *owner, VALUE v_view, VALUE v_model);
  override int rowCount(const QModelIndex &parent = QModelIndex()) const;
  override QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const;
}; // class CBModel

CBModel::CBModel(QComboBox *owner, VALUE v_view, VALUE v_model):
inherited(owner),
Owner(*owner),
View(v_view),
Model(v_model)
{
  /* this is just so that it is properly marked!
   * Note that v_view is in fact the same as owner, so it should be safe
   */
  setProperty(R_QT_MODEL_PROPERTYID, QVariant::fromValue(RValue(v_model)));
}

int 
CBModel::rowCount(const QModelIndex &/*parent*/) const
{
  //trace("rowCount()");   // called ridiculously often
  return RPP::Fixnum(Model.call("model_rowCount"));
}

QVariant 
CBModel::data(const QModelIndex &index, int role) const
{
  trace3("data(%d, %d, role:%d)", index.row(), index.column(), role);
  /* FIXME. this is only the value.
   * In the case that a 'con' has value :key, then we need that as well at this point
   */
  const RPP::Object v_key = Model.call("model_index2key", index.row()); 
  if (v_key.isNil()) return QVariant();
  const RPP::Object v_record = Model.call("model_key2data", v_key);
  if (v_record.isNil()) return QVariant();
  // get the correct connector.
  static const char *RoleMethod[15] = { "display", "decoration", "edit", "tooltip", 
					"statustip", 
					"whatsthis", // 5 
					"font", "textalignment", "background",
					"foreground", 
					"checkstate", // 10
					"accessibletext", "accessibledescription" ,
					"sizehint",
					"initialsortorder" };
  if (role >= 15 || role < 0) return QVariant();
  const char *const rolemethod = RoleMethod[role];
  // Q: is this smart? Better use a single 'roleconnector(rolemethod)' method.
  //    the old code used that too.
  // Otherwise we get a method 'font' and 'edit' which are confusing maybe?
  // A: but these methods MUST already exist on the view to begin with.
  //    Just use the same name as how to assign the connector and it will be fine.
  if (!View.respond_to(rolemethod)) return QVariant();
  const RPP::Object v_con = View.call(rolemethod);
  if (v_con.isNil()) return QVariant();
  RPP::Object v_value;
  if (v_con.isSymbol() && RPP::Symbol(v_con).to_id() == rb_intern("key"))
      v_value = v_key;
  else
    {
      track2("Calling %s::model_apply_getter(%s)", v_record, v_con);
      v_value = cModel.call("model_apply_getter", v_record, v_con);
      if (v_value.isNil()) return QVariant();
      trace2("v_value = %s, class = %s", v_value.inspect(), v_value.classname());
      trace1("v_value.respond_to('model_value') = %d", (int)v_value.respond_to("model_value"));
      track1("v_value.respond_to?('model_value') = %s", v_value.call("respond_to?", "model_value"));
      v_value = cModel.call("model_unwrap", v_value);
    }
  switch (role)
    {
    case Qt::DisplayRole:
      break;
    case Qt::DecorationRole:
      {
	// the easiest way to convert 'anything' to a QColor:
	const RPP::QColor v_color = cColor.new_instance(v_value);
	return *v_color;
      }
    case Qt::SizeHintRole:
      // we must return a QSize
      rb_raise(rb_eNotImpError, "SizeHintRole");
    case Qt::FontRole:
      // we must return a QFont
      rb_raise(rb_eNotImpError, "FontRole");
    case Qt::TextAlignmentRole:
      // we must return ?
      rb_raise(rb_eNotImpError, "TextAlignmentRole");
    case Qt::CheckStateRole:
      // we must return ?
      rb_raise(rb_eNotImpError, "CheckStateRole");
    case Qt::BackgroundRole: 
      // we must return a color
    case Qt::ForegroundRole:
      // we must return a color
    default:
      // we must return ???
      rb_raise(rb_eNotImpError, "role: %s", rolemethod);
    }
  // we must return a QString. It seems reasonable to use 'to_str' for this.
  // But that fails on the common case 'nil' and integers too etc..
  const RPP::String v_strval = v_value.to_s();
  trace2("data() returns %s %s", v_value.classname(), v_value.inspect());
  return v2QString(v_strval);
}

/* override
 *
 * Note that the passed model normally is uninitialized
 */
static VALUE cComboBox_addModel(VALUE v_self, VALUE v_model)
{
  const RPP::QObject<QComboBox> self = v_self;
  track2("%s::addModel(%s)", v_self, v_model);
  const VALUE r = self.super(v_model);
  trace("addModel, creating new CBModel");
  self->setModel(new CBModel(self, v_self, v_model));
  trace("OK");
  return r;
}

void
init_combobox(RPP::Module qt, RPP::Class cWidget)
{
  const RPP::Class cComboBox = qt.define_class("ComboBox", cWidget); //AbstractListView);
  cComboBox.define_alloc_func(cComboBox_alloc)
	   .define_method("addModel", cComboBox_addModel)
	   .define_method("count", cComboBox_count)
	   .define_method("maxCount_get", cComboBox_maxCount_get)
	   .define_method("maxCount=", cComboBox_maxCount_set)
	   .define_method("maxVisibleItems_get", cComboBox_maxVisibleItems_get)
	   .define_method("maxVisibleItems=", cComboBox_maxVisibleItems_set)
	   .define_method("minimumContentsLength_get", cComboBox_minimumContentsLength_get)
	   .define_method("minimumContentsLength=", cComboBox_minimumContentsLength_set)
	   .define_method("currentIndex_get", cComboBox_currentIndex_get)
	   .define_method("currentIndex=", cComboBox_currentIndex_set)
	   .define_method("currentText_get", cComboBox_currentText_get)
	   .define_method("currentText=", cComboBox_currentText_set)
	   .define_method("editable_get", cComboBox_editable_p)
	   .define_method("editable=", cComboBox_editable_set)
	   .define_method("frame_get", cComboBox_frame_p)
	   .define_method("frame=", cComboBox_frame_set)
	   .define_method("iconSize_get", cComboBox_iconSize_get)
	   .define_method("iconSize=", cComboBox_iconSize_set)
	   ;
} // init_combobox
} // namespace R_Qt
