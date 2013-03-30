#if !defined(_RPP_BO_H_)
#define _RPP_BO_H_

#include <ruby/ruby.h>

namespace RPP {

#define override virtual

// forwards
class Array;
class Class;
class Fixnum;
class Proc;
class String;

enum E_SAFETY 
{ 
  // Passing VERYUNSAFE will disable all checking.
  VERYUNSAFE,
  // Passing UNSAFE will disable typecheck for Qnil.
  UNSAFE, 
  // Passing SAFE will cause a typecheck for any value
  SAFE
}; // for use with constructors.

typedef VALUE (*ArgVMethod)(int argc, VALUE *argv, VALUE v_self);
typedef VALUE (*Arg0Method)(VALUE v_self);
typedef VALUE (*Arg1Method)(VALUE v_self, VALUE v_1);
typedef VALUE (*Arg2Method)(VALUE v_self, VALUE v_1, VALUE v_2);
typedef VALUE (*Arg3Method)(VALUE v_self, VALUE v_1, VALUE v_2, VALUE v_3);
typedef VALUE (*Arg4Method)(VALUE v_self, VALUE v_1, VALUE v_2, VALUE v_3, VALUE v_4);

// prefix is 'iv' (instancevar) or 'cv' (classvar) or 'gv' (globalvar) 
// note that Fixnum has ambiguous casts of ->VALUE and ->int (since VALUE == int)...
#define RPP_SETTERS(klass, prefix) \
  const klass &prefix##_set(const char *name, VALUE v) const \
    { \
      rb_##prefix##_set(V, name, v); \
      return *this; \
    } \
  const klass &prefix##_set(const char *name, Fixnum v) const; /*FORWARDED*/ \
  const klass &prefix##_set(const char *name, bool v) const \
    { \
      rb_##prefix##_set(V, name, v ? Qtrue : Qfalse); \
      return *this; \
    } \
  const klass &prefix##_set(const char *name, int v) const \
    { \
      rb_##prefix##_set(V, name, INT2NUM(v)); \
      return *this; \
    } \
  const klass &prefix##_set(const char *name, double v) const \
    { \
      rb_##prefix##_set(V, name, DBL2NUM(v)); \
      return *this; \
    } \
  const klass &prefix##_set(const char *name, const char *v) const \
    { \
      rb_##prefix##_set(V, name, rb_str_new_cstr(v)); \
      return *this; \
    }

class BasicObject
{
protected:
  VALUE V;
protected:
  BasicObject(VALUE v): V(v) {}
public:
  BasicObject(): BasicObject(Qnil) {}
  virtual ~BasicObject() {}
  // This is just what C++ will do anyway: BasicObject(const BasicObject &other): V(other.V) {}
  VALUE value() const { return V; }
  VALUE &value_ref() { return V; }
  operator VALUE() const { return V; }
  VALUE operator*() const { return V; }
  VALUE *operator &() { return &V; }
  virtual void assign(VALUE v, E_SAFETY /*safe*/ = SAFE) { V = v; }
  void operator=(VALUE v) { assign(v, UNSAFE); }
  /* CAUSES ZILLION AMBIGUITIES
  void operator=(BasicObject v) { V = v; }
  */
  bool test() const { return RTEST(V); }
  bool isNil() const { return NIL_P(V); }
  bool isClass() const { return TYPE(V) == T_CLASS; } 
  bool isModule() const { return TYPE(V) == T_MODULE; } 
  bool isArray() const { return TYPE(V) == T_ARRAY; }
  bool isData() const { return TYPE(V) == T_DATA; }
  bool isHash() const { return TYPE(V) == T_HASH; }
  bool isFixnum() const { return FIXNUM_P(V); }
  bool isSymbol() const { return SYMBOL_P(V); }
  bool isRange() const { return rb_obj_is_kind_of(V, rb_cRange); }
  bool isProc() const { return RTEST(rb_obj_is_proc(V)); }
  bool isLambda() const { return isProc() && rb_proc_lambda_p(V); }

  // CALLS
  VALUE call(const char *method) const
    {
      return rb_funcall(V, rb_intern(method), 0);
    }
  VALUE call(const char *method, VALUE v_1) const
    {
      return rb_funcall(V, rb_intern(method), 1, v_1);
    }
  // ONLY single arg calls have some shortcuts.
  VALUE call(const char *method, bool v) const
    {
      return rb_funcall(V, rb_intern(method), 1, v ? Qtrue : Qfalse);
    }
  VALUE call(const char *method, Fixnum v) const; // FORWARDED
  VALUE call(const char *method, int v) const
    {
      return rb_funcall(V, rb_intern(method), 1, INT2NUM(v));
    }
  VALUE call(const char *method, double v) const
    {
      return rb_funcall(V, rb_intern(method), 1, DBL2NUM(v));
    }
  VALUE call(const char *method, const char *v) const
    {
      return rb_funcall(V, rb_intern(method), 1, rb_str_new_cstr(v));
    }
  VALUE call(const char *method, VALUE v_1, VALUE v_2) const
    {
      return rb_funcall(V, rb_intern(method), 2, v_1, v_2);
    }
  VALUE call(const char *method, VALUE v_1, VALUE v_2, VALUE v_3) const
    {
      return rb_funcall(V, rb_intern(method), 3, v_1, v_2, v_3);
    }
  VALUE call(const char *method, VALUE v_1, VALUE v_2, VALUE v_3, VALUE v_4) const
    {
      return rb_funcall(V, rb_intern(method), 4, v_1, v_2, v_3, v_4);
    }
  /* generic. UNSAFE
  VALUE call(const char *method, int argc, const VALUE *argv) const
    {
      return rb_funcall2(V, rb_intern(method), argc, argv);
    }
  VALUE call_public(const char *method, int argc, const VALUE *argv) const
    {
      // rb_funcall3 checks for 'public' where rb_funcall2 ignores it completely.
      return rb_funcall3(V, rb_intern(method), argc, argv);
    }
  */
  VALUE call_public(const char *method) const
    {
      return rb_funcall3(V, rb_intern(method), 0, (VALUE *)0);
    }
  VALUE call_public(const char *method, VALUE v_1) const
    {
      return rb_funcall3(V, rb_intern(method), 1, &v_1);
    }
  VALUE call_public(const char *method, Fixnum v_1) const; /* FORWARDED */
  VALUE call_public(const char *method, int i) const
    {
      const VALUE v = INT2NUM(i);
      return rb_funcall3(V, rb_intern(method), 1, &v);
    }
  VALUE call_public(const char *method, bool b) const
    {
      const VALUE v = b ? Qtrue : Qfalse;
      return rb_funcall3(V, rb_intern(method), 1, &v);
    }
  VALUE call_public(const char *method, double f) const
    {
      const VALUE v = DBL2NUM(f);
      return rb_funcall3(V, rb_intern(method), 1, &v);
    }
  VALUE call_public(const char *method, const char *s) const
    {
      const VALUE v = rb_str_new_cstr(s);
      return rb_funcall3(V, rb_intern(method), 1, &v);
    }
  VALUE call_public(const char *method, VALUE v_1, VALUE v_2) const
    {
      VALUE args[2] = { v_1, v_2 };
      return rb_funcall3(V, rb_intern(method), 2, args);
    }
  // Etc.. etc.. (?)
 
  VALUE call(const char *method, Array args); // FORWARDED
  VALUE call_public(const char *method, Array args); // FORWARDED

  /* AND NOW ALL HELL BREAKS LOOSE.
   * 
   * These work like 'call', but they accept a 'block'.
   *
   * According to Eugene, the callback block always takes two arguments.
   * The first is the yielded value, the second is the last argument to this method.
   *
   * Since it happens often that only a block is passed, I added some more variations with this condition.
   */
  VALUE call_with_block(const char *method, Arg1Method callback, VALUE v_arg = Qnil) const
    {
      return rb_block_call(V, rb_intern(method), 0, (VALUE*)0, RUBY_METHOD_FUNC(callback), v_arg);
    }
  VALUE call_with_block(const char *method, Arg1Method callback, Fixnum v_arg) const; // FORWARDED
  VALUE call_with_block(const char *method, Arg1Method callback, bool arg) const
    {
      return rb_block_call(V, rb_intern(method), 0, (VALUE*)0, RUBY_METHOD_FUNC(callback), arg ? Qtrue : Qfalse);
    }
  VALUE call_with_block(const char *method, Arg1Method callback, int arg) const
    {
      return rb_block_call(V, rb_intern(method), 0, (VALUE*)0, RUBY_METHOD_FUNC(callback), INT2NUM(arg));
    }
  VALUE call_with_block(const char *method, Arg1Method callback, double arg) const
    {
      return rb_block_call(V, rb_intern(method), 0, (VALUE*)0, RUBY_METHOD_FUNC(callback), DBL2NUM(arg));
    }
  VALUE call_with_block(const char *method, Arg1Method callback, const char *arg) const
    {
      return rb_block_call(V, rb_intern(method), 0, (VALUE*)0, RUBY_METHOD_FUNC(callback), rb_str_new_cstr(arg));
    }
  VALUE call_with_block(const char *method, Arg1Method callback, VALUE v_1, VALUE v_2) const
    {
      return rb_block_call(V, rb_intern(method), 0, (VALUE*)0, RUBY_METHOD_FUNC(callback), 
			   rb_ary_new3(2, v_1, v_2));
    }
  VALUE call_with_block(const char *method, VALUE arg1, Arg1Method callback, VALUE v_arg = Qnil) const
    {
      return rb_block_call(V, rb_intern(method), 1, &arg1, RUBY_METHOD_FUNC(callback), v_arg);
    }
  VALUE call_with_block(const char *method, Fixnum arg1, Arg1Method callback, VALUE v_arg = Qnil) const; /*FORWARDED */
  VALUE call_with_block(const char *method, bool arg1, Arg1Method callback, VALUE v_arg = Qnil) const
    {
      VALUE v = arg1 ? Qtrue : Qfalse;
      return rb_block_call(V, rb_intern(method), 1, &v, RUBY_METHOD_FUNC(callback), v_arg);
    }
  VALUE call_with_block(const char *method, int arg1, Arg1Method callback, VALUE v_arg = Qnil) const
    {
      VALUE v = INT2NUM(arg1);
      return rb_block_call(V, rb_intern(method), 1, &v, RUBY_METHOD_FUNC(callback), v_arg);
    }
  VALUE call_with_block(const char *method, double arg1, Arg1Method callback, VALUE v_arg = Qnil) const
    {
      VALUE v = DBL2NUM(arg1);
      return rb_block_call(V, rb_intern(method), 1, &v, RUBY_METHOD_FUNC(callback), v_arg);
    }
  VALUE call_with_block(const char *method, const char *arg1, Arg1Method callback, VALUE v_arg = Qnil) const
    {
      VALUE v = rb_str_new_cstr(arg1);
      return rb_block_call(V, rb_intern(method), 1, &v, RUBY_METHOD_FUNC(callback), v_arg);
    }
  VALUE call_with_block(const char *method, VALUE arg1, VALUE arg2, Arg1Method callback, VALUE v_arg = Qnil) const
    {
      VALUE args[2] = { arg1, arg2 };
      return rb_block_call(V, rb_intern(method), 2, args, RUBY_METHOD_FUNC(callback), v_arg);
    }
  // etc. etc. 
 
  /* and the next bunch....
   *
   * call_with_block adds given block to the call.
   * call_passing_block passes on the block given to us by the caller.
   */
  VALUE call_passing_block(const char *method) const
    {
      return rb_funcall_passing_block(V, rb_intern(method), 0, (VALUE *)0);
    }
  VALUE call_passing_block(const char *method, VALUE v_1) const
    {
      return rb_funcall_passing_block(V, rb_intern(method), 1, &v_1);
    }
  VALUE call_passing_block(const char *method, VALUE v_1, VALUE v_2) const
    {
      VALUE args[2] = { v_1, v_2 };
      return rb_funcall_passing_block(V, rb_intern(method), 2, args);
    }
  VALUE call_passing_block(const char *method, VALUE v_1, VALUE v_2, VALUE v_3) const
    {
      VALUE args[3] = { v_1, v_2, v_3 };
      return rb_funcall_passing_block(V, rb_intern(method), 3, args);
    }
  VALUE call_passing_block(const char *method, VALUE v_1, VALUE v_2, VALUE v_3, VALUE v_4) const
    {
      VALUE args[4] = { v_1, v_2, v_3, v_4 };
      return rb_funcall_passing_block(V, rb_intern(method), 4, args);
    }

  // And some static call_supers..... 
  static VALUE super() { return rb_call_super(0, (VALUE *)0); }
  static VALUE super(int argc, VALUE *argv) { return rb_call_super(argc, argv); }
  static VALUE super(VALUE v_1) { return rb_call_super(1, &v_1); }
  static VALUE super(VALUE v_1, VALUE v_2) 
    { 
      VALUE args[2] = { v_1, v_2 };
      return rb_call_super(2, args); 
    }
  static VALUE super(VALUE v_1, VALUE v_2, VALUE v_3)
    { 
      VALUE args[3] = { v_1, v_2, v_3 };
      return rb_call_super(3, args); 
    }
  static VALUE super(VALUE v_1, VALUE v_2, VALUE v_3, VALUE v_4)
    { 
      VALUE args[4] = { v_1, v_2, v_3, v_4 };
      return rb_call_super(4, args); 
    }

  /* This is always safe anyway:      According to irb	'nil.to_i' is 0.
   But NUM2INT(Qnil) fails anyway. So:
  int to_i() const { return NUM2INT(call("to_i")); }
  double to_f() const { return NUM2DBL(call("to_f")); }

  TOO EXPENSIVE!
  */

  int to_i() const 
    { 
      switch (type())
	{
	case T_NIL: 
	  return 0;
	default:
	  return NUM2INT(*this);
	}
    }
  double to_f() const 
    { 
      if (type() == T_NIL) return 0.0;
      return NUM2DBL(*this);
    }
  VALUE iv(const char *varname) const { return rb_iv_get(V, varname); }
  RPP_SETTERS(BasicObject, iv);
  bool is_kind_of(VALUE klass) const { return rb_obj_is_kind_of(V, klass); }

  // avoid the next one. But it is required, sometimes.
  int type() const { return TYPE(V); }
  void gc_mark() const { rb_gc_mark(V); }
  const char *classname() const { return rb_obj_classname(V); }

  // The following are somewhat unsafe, in that you must check 'isNil()' on the result
  // or 'test()'!
  Array check_array_type() const; // FORWARDED
  String check_string_type() const; // FORWARDED

  VALUE yield() const { return rb_yield(V); }
  static VALUE yield(bool arg) { return rb_yield(arg ? Qtrue : Qfalse); }
  static VALUE yield(int arg) { return rb_yield(INT2NUM(arg)); }
  static VALUE yield(double arg) { return rb_yield(DBL2NUM(arg)); }
  static VALUE yield(Fixnum arg); // FORWARDED
  static VALUE yield(const char *arg) { return rb_yield(rb_str_new_cstr(arg)); }
  static VALUE yield(VALUE arg) { return rb_yield(arg); }
  static VALUE yield(VALUE arg1, VALUE arg2) 
    {
      return rb_yield_values(2, arg1, arg2);
    }
  static VALUE yield(VALUE arg1, VALUE arg2, VALUE arg3) 
    {
      return rb_yield_values(3, arg1, arg2, arg3);
    }
  static VALUE yield(VALUE arg1, VALUE arg2, VALUE arg3, VALUE arg4) 
    {
      return rb_yield_values(4, arg1, arg2, arg3, arg4);
    }

  // statics
  static bool block_given() { return rb_block_given_p(); }
  static bool block_given_p() { return rb_block_given_p(); }
  static VALUE proc() { return rb_block_proc(); }
}; // class BasicObject

} // namespace RPP

// AVOID THESE.	    call("to_s") is better and to_s() as well.
#define RQT_TO_S(x) rb_funcall(x, rb_intern("to_s"), 0)
#define TO_CSTR(x) RSTRING_PTR(RQT_TO_S(x))
#define INSPECT(x) RSTRING_PTR(rb_inspect(x))

#if defined(TRACE)
#define trace(arg) fprintf(stderr, __FILE__ ":%d:" arg "\n", __LINE__);
#define trace1(arg, a) fprintf(stderr, __FILE__ ":%d:" arg "\n", __LINE__, a);
#define trace2(arg, a, b) fprintf(stderr, __FILE__ ":%d:" arg "\n", __LINE__, a, b);
#define trace3(arg, a, b, c) fprintf(stderr, __FILE__ ":%d:" arg "\n", __LINE__, a, b, c);
#define trace4(arg, a, b, c, d) fprintf(stderr, __FILE__ ":%d:" arg "\n", __LINE__, a, b, c, d);
#define trace5(arg, a, b, c, d, e) fprintf(stderr, __FILE__ ":%d:" arg "\n", __LINE__, a, b, c, d, e);
#define track1(arg, a) fprintf(stderr, __FILE__ ":%d:" arg "\n", __LINE__, INSPECT(a));
#define track2(arg, a, b) fprintf(stderr, __FILE__ ":%d:" arg "\n", __LINE__, INSPECT(a), INSPECT(b));
#define track3(arg, a, b, c) fprintf(stderr, __FILE__ ":%d:" arg "\n", __LINE__, INSPECT(a), INSPECT(b), INSPECT(c));
#define track4(arg, a, b, c, d) fprintf(stderr, __FILE__ ":%d:" arg "\n", __LINE__, INSPECT(a), INSPECT(b), \
					INSPECT(c), INSPECT(d));
#else // !TRACE
#define trace(arg)
#define trace1(arg, a)
#define trace2(arg, a, b)
#define trace3(arg, a, b, c)
#define trace4(arg, a, b, c, d)
#define trace5(arg, a, b, c, d, e)
#define track1(arg, a)
#define track2(arg, a, b)
#define track3(arg, a, b, c)
#define track4(arg, a, b, c, d)
#endif // !TRACE

#endif  //_RPP_BO_H_
