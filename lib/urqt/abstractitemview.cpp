
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#pragma implementation

#include "abstractitemview.h"
#include "application.h"
#include "urqtCore/size.h"
#include "urqtCore/intvector.h"
#include <QtWidgets/QAbstractItemView>
#include "ruby++/ruby++all.h"
#include <assert.h>

namespace R_Qt {

RPP::Class
cAbstractItemView,
cAbstractListView;

static VALUE
cAbstractItemView_dragDropMode_get(VALUE v_self)
{
  const QAbstractItemView::DragDropMode ddm = RPP::QObject<QAbstractItemView>(v_self)->dragDropMode();
  switch (ddm)
    {
      case QAbstractItemView::NoDragDrop: return RPP::Symbol("none");
      case QAbstractItemView::DragOnly: return RPP::Symbol("drag_only");
      case QAbstractItemView::DropOnly: return RPP::Symbol("drop_only");
      case QAbstractItemView::DragDrop: return RPP::Symbol("drag_drop");
      case QAbstractItemView::InternalMove: return RPP::Symbol("internal_move");
    }
  rb_raise(rb_eNotImpError, "unsupported DragDropMode %d", int(ddm));
}

static VALUE
cAbstractItemView_dragDropMode_set(VALUE v_self, VALUE v_sym)
{
  const RPP::QObject<QAbstractItemView> self = v_self;
  self.check_frozen();
  RPP::Dictionary dct(cAbstractItemView.cv("@@dragdropmodes"), RPP::VERYUNSAFE);
  if (!dct.isHash())
    {
      cAbstractItemView.cv_set("@@dragdropmodes", dct = RPP::Dictionary());
#define ENTRY_DO(sym, enumval) dct[#sym] = RPP::Fixnum(QAbstractItemView::enumval)
      ENTRY_DO(default, NoDragDrop); 
      ENTRY_DO(no_drag_drop, NoDragDrop); 
      ENTRY_DO(noDragDrop, NoDragDrop); 
      ENTRY_DO(drag_only, DragOnly); 
      ENTRY_DO(dragOnly, DragOnly); 
      ENTRY_DO(drop_only, DropOnly); 
      ENTRY_DO(dropOnly, DropOnly); 
      ENTRY_DO(internal_move, InternalMove); 
      ENTRY_DO(internalMove, InternalMove); 
#undef ENTRY_DO
    }
  self->setDragDropMode(QAbstractItemView::DragDropMode(RPP::Fixnum(dct[v_sym]).to_i()));
  return v_sym;

}

static VALUE
cAbstractItemView_selectionMode_get(VALUE v_self)
{
  const QAbstractItemView::SelectionMode selmod = RPP::QObject<QAbstractItemView>(v_self)->selectionMode();
  switch (selmod)
    {
#define ENTRY_DO(sym, enum) \
      case QAbstractItemView::enum: return RPP::Symbol(#sym)
      ENTRY_DO(none, NoSelection);
      ENTRY_DO(single, SingleSelection);
      ENTRY_DO(contiguous, ContiguousSelection);
      ENTRY_DO(extended, ExtendedSelection);
      ENTRY_DO(multi, MultiSelection);
#undef ENTRY_DO
    }
  rb_raise(rb_eNotImpError, "unsupported SelectionMode %d", int(selmod));
}

static VALUE
cAbstractItemView_selectionMode_set(VALUE v_self, VALUE v_sym)
{
  const RPP::QObject<QAbstractItemView> self = v_self;
  self.check_frozen();
  RPP::Dictionary dct(cAbstractItemView.cv("@@selectionmodes"), RPP::VERYUNSAFE);
  if (!dct.isHash())
    {
      cAbstractItemView.cv_set("@@selectionmodes", dct = RPP::Dictionary());
#define ENTRY_DO(sym, enumval) dct[#sym] = RPP::Fixnum(QAbstractItemView::enumval)
      ENTRY_DO(none, NoSelection);
      ENTRY_DO(single, SingleSelection);
      ENTRY_DO(contiguous, ContiguousSelection);
      ENTRY_DO(extended, ExtendedSelection);
      ENTRY_DO(multi, MultiSelection);
      ENTRY_DO(default, SingleSelection); 
#undef ENTRY_DO
    }
  self->setSelectionMode(QAbstractItemView::SelectionMode(RPP::Fixnum(dct[v_sym]).to_i()));
  return v_sym;
}

static VALUE
cAbstractItemView_editTriggers_get(VALUE v_self)
{
  QAbstractItemView::EditTriggers et = RPP::QObject<QAbstractItemView>(v_self)->editTriggers();
  const RPP::Array ary;
#define ENTRY_DO(sym, enum) \
  if (et & QAbstractItemView::enum) \
    { \
      ary << RPP::Symbol(#sym); \
      et &= ~QAbstractItemView::enum; \
    }
  ENTRY_DO(current_changed, CurrentChanged);
  ENTRY_DO(double_clicked, DoubleClicked);
  ENTRY_DO(selected_clicked, SelectedClicked);
  ENTRY_DO(edit_key_pressed, EditKeyPressed);
  ENTRY_DO(any_key_pressed, AnyKeyPressed);
#undef ENTRY_DO
  if (et) rb_raise(rb_eNotImpError, "unsupported bits %u in EditTriggers", (unsigned int)et);
  return ary;
}

static VALUE
cAbstractItemView_selectionBehavior_get(VALUE v_self)
{
  const QAbstractItemView::SelectionBehavior selbev 
    = RPP::QObject<QAbstractItemView>(v_self)->selectionBehavior();
  switch (selbev)
    {
#define ENTRY_DO(sym, enum) \
      case QAbstractItemView::enum: return RPP::Symbol(#sym)
      ENTRY_DO(items, SelectItems);
      ENTRY_DO(rows, SelectRows);
      ENTRY_DO(columns, SelectColumns);
#undef ENTRY_DO
    }
  rb_raise(rb_eNotImpError, "unsupported SelectionBehavior %d", int(selbev));
}

static VALUE
cAbstractItemView_selectionBehavior_set(VALUE v_self, VALUE v_sym)
{
  const RPP::QObject<QAbstractItemView> self = v_self;
  self.check_frozen();
  RPP::Dictionary dct(cAbstractItemView.cv("@@selectionbehaves"), RPP::VERYUNSAFE);
  if (!dct.isHash())
    {
      cAbstractItemView.cv_set("@@selectionbehaves", dct = RPP::Dictionary());
#define ENTRY_DO(sym, enumval) dct[#sym] = RPP::Fixnum(QAbstractItemView::enumval)
      ENTRY_DO(items, SelectItems);
      ENTRY_DO(default, SelectItems);
      ENTRY_DO(rows, SelectRows);
      ENTRY_DO(columns, SelectColumns);
      ENTRY_DO(cols, SelectColumns);
#undef ENTRY_DO
    }
  self->setSelectionMode(QAbstractItemView::SelectionMode(RPP::Fixnum(dct[v_sym]).to_i()));
  return v_sym;
}

static VALUE
cAbstractItemView_editTriggers_set(int argc, VALUE *argv, VALUE v_self)
{
  const RPP::QObject<QAbstractItemView> self = v_self;
  self.check_frozen();
  RPP::Dictionary dct(cAbstractItemView.cv("@@edittriggers"), RPP::VERYUNSAFE);
  if (!dct.isHash())
    {
      cAbstractItemView.cv_set("@@edittriggers", dct = RPP::Dictionary());
#define ENTRY_DO(sym, enumval) dct[#sym] = RPP::Fixnum(QAbstractItemView::enumval)
      ENTRY_DO(no_edit_triggers, NoEditTriggers);
      ENTRY_DO(none, NoEditTriggers);
      ENTRY_DO(noEditTriggers, NoEditTriggers);
      ENTRY_DO(default, NoEditTriggers);
      ENTRY_DO(current_changed, CurrentChanged);
      ENTRY_DO(currentChanged, CurrentChanged);
      ENTRY_DO(double_clicked, DoubleClicked);
      ENTRY_DO(doubleClicked, DoubleClicked);
      ENTRY_DO(selected_clicked, SelectedClicked);
      ENTRY_DO(selectedClicked, SelectedClicked);
      ENTRY_DO(edit_key_pressed, EditKeyPressed);
      ENTRY_DO(editKeyPressed, EditKeyPressed);
      ENTRY_DO(edit_key, EditKeyPressed);
      ENTRY_DO(any_key_pressed, AnyKeyPressed);
      ENTRY_DO(anyKeyPressed, AnyKeyPressed);
      ENTRY_DO(any_key, AnyKeyPressed);
#undef ENTRY_DO
    }
  QAbstractItemView::EditTriggers triggers;
  assert(triggers == 0);
  if (argc == 1 && TYPE(*argv) == T_ARRAY)
    {
      const RPP::Array ary = *argv;
      argc = ary.len(), argv = ary.ptr();
    }
  for (int N = 0; N < argc; N++, argv++)
    triggers |= QAbstractItemView::EditTrigger(RPP::Fixnum(dct[*argv]).to_i());
  self->setEditTriggers(triggers);
  return Qnil;
}

static VALUE
cAbstractItemView_defaultDropAction_get(VALUE v_self)
{
  const Qt::DropAction dda = RPP::QObject<QAbstractItemView>(v_self)->defaultDropAction();
  switch (dda)
    {
      case Qt::CopyAction: return RPP::Symbol("copy");
      case Qt::MoveAction: return RPP::Symbol("move");
      case Qt::LinkAction: return RPP::Symbol("link");
      case Qt::IgnoreAction: return RPP::Symbol("ignore");
      case Qt::TargetMoveAction: return RPP::Symbol("target_move");
      default: break;
    }
  rb_raise(rb_eNotImpError, "unsupported default DropAction %d", int(dda));
}

static VALUE
cAbstractItemView_defaultDropAction_set(VALUE v_self, VALUE v_sym)
{
  const RPP::QObject<QAbstractItemView> self = v_self;
  self.check_frozen();
  RPP::Dictionary dct(cAbstractItemView.cv("@@dropactions"), RPP::VERYUNSAFE);
  if (!dct.isHash())
    {
      cAbstractItemView.cv_set("@@dropactions", dct = RPP::Dictionary());
#define ENTRY_DO(sym, enumval) dct[#sym] = RPP::Fixnum(Qt::enumval)
      ENTRY_DO(default, CopyAction); 
      ENTRY_DO(copy, CopyAction); 
      ENTRY_DO(copyAction, CopyAction);
      ENTRY_DO(move, MoveAction); 
      ENTRY_DO(moveAction, MoveAction); 
      ENTRY_DO(link, LinkAction); 
      ENTRY_DO(linkAction, LinkAction); 
      ENTRY_DO(ignore, IgnoreAction); 
      ENTRY_DO(ignoreAction, IgnoreAction); 
      ENTRY_DO(target_move, TargetMoveAction); 
      ENTRY_DO(targetMove, TargetMoveAction); 
      ENTRY_DO(targetMoveAction, TargetMoveAction); 
#undef ENTRY_DO
    }
  self->setDefaultDropAction(Qt::DropAction(RPP::Fixnum(dct[v_sym]).to_i()));
  return v_sym;
}

RPP_DECL_BOOL_ACCESSOR2(cAbstractItemView, dropIndicatorShown, 
		        RPP::QObject<QAbstractItemView>, showDropIndicator,
			setDropIndicatorShown)
	  
RPP_DECL_BOOL_ACCESSOR2(cAbstractItemView, alternatingRowColors, 
		        RPP::QObject<QAbstractItemView>, alternatingRowColors,
			setAlternatingRowColors)

RPP_DECL_BOOL_ACCESSOR2(cAbstractItemView, autoScroll, 
		        RPP::QObject<QAbstractItemView>, hasAutoScroll, setAutoScroll)

RPP_DECL_BOOL_ACCESSOR2(cAbstractItemView, dropOverwriteMode, 
		        RPP::QObject<QAbstractItemView>,
			dragDropOverwriteMode, setDragDropOverwriteMode)

RPP_DECL_BOOL_ACCESSOR2(cAbstractItemView, dragEnabled, 
		        RPP::QObject<QAbstractItemView>, dragEnabled, setDragEnabled)

RPP_DECL_SIZE_ACCESSOR2(cAbstractItemView, iconSize,
		        RPP::QObject<QAbstractItemView>, iconSize, setIconSize)

  /* NEVER MIND. QAbstractItemView::dataChanged() is protected!!
static VALUE 
cAbstractItemView_dataChanged(int argc, VALUE *argv, VALUE v_self)
{
  RPP::QModelIndex topleft, bottomright;
  RPP::QIntVector vector(RPP::UNSAFE); // since the default constructor creates one
  RPP::Scan(argc, argv, topleft, bottomright).opt(vector);
  const RPP::QObject<QAbstractItemView> self = v_self;
  QVector<int> room;
  self->dataChanged(topleft, bottomright, vector.to_q(room));
}
*/

void
init_abstractitemview(RPP::Module qt, RPP::Class)
{
  cAbstractItemView = qt.define_class("AbstractItemView", cAbstractScrollArea);
  cAbstractItemView.define_method("dragDropMode_get", cAbstractItemView_dragDropMode_get)
		   .define_method("dragDropMode=", cAbstractItemView_dragDropMode_set)
		   .define_method("dropIndicatorShown_get", cAbstractItemView_dropIndicatorShown_p)
		   .define_method("dropIndicatorShown=", cAbstractItemView_dropIndicatorShown_set)
		   .define_method("alternatingRowColors_get", cAbstractItemView_alternatingRowColors_p)
		   .define_method("alternatingRowColors=", cAbstractItemView_alternatingRowColors_set)
		   .define_method("autoScroll_get", cAbstractItemView_autoScroll_p)
		   .define_method("autoScroll=", cAbstractItemView_autoScroll_set)
		   .define_method("defaultDropAction_get", cAbstractItemView_defaultDropAction_get)
		   .define_method("defaultDropAction=", cAbstractItemView_defaultDropAction_set)
		   .define_method("dropOverwriteMode_get", cAbstractItemView_dropOverwriteMode_p)
		   .define_method("dropOverwriteMode=", cAbstractItemView_dropOverwriteMode_set)
		   .define_method("dragEnabled_get", cAbstractItemView_dragEnabled_p)
		   .define_method("dragEnabled=", cAbstractItemView_dragEnabled_set)
		   .define_method("editTriggers_get", cAbstractItemView_editTriggers_get)
		   .define_method("editTriggers=", cAbstractItemView_editTriggers_set)
		   .define_method("iconSize_get", cAbstractItemView_iconSize_get)
		   .define_method("iconSize=", cAbstractItemView_iconSize_set)
		   .define_method("selectionMode_get", cAbstractItemView_selectionMode_get)
		   .define_method("selectionMode=", cAbstractItemView_selectionMode_set)
		   .define_method("selectionBehavior_get", cAbstractItemView_selectionBehavior_get)
		   .define_method("selectionBehavior=", cAbstractItemView_selectionBehavior_set)
		    ;
  cAbstractListView = qt.define_class("AbstractListView", cAbstractItemView);
}; // class AbstractItemView

} // namespace R_Qt 
