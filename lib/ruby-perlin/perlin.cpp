/*
Ruby module that is built according to the Perlin Noise function
located at http://freespace.virgin.net/hugo.elias/models/m_perlin.htm

The MIT License

Copyright (c) 2009 Brian Jones

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.


Copyright (c) 2011 Eugene Brazwick
Several alterations were made so that 'run' returns a value between 0.0 and 1.0
under all circumstances.
Usint different ratios for smoothing perlins.
Fixed 'bug' that all arguments became integers.

Currently NOT thread-safe.  two perlin calls share a 'seed' static. It would be
better to use a temporary C++ class instance for the processing.

Using Smoothing == true returns values between 0.4 and 0.6, eventhough 0.0 and 1.0
are technically possible.
So the advise is to use a higher octave number and a higher persistence.
*/

#include <ruby.h>
// #include <ruby/dl.h>
#include <math.h>

#define rb_check_float_type(c) (rb_type(c) == T_FLOAT ? (c) : Qnil)

VALUE rb_cPerlin;

static inline double num2dbl(VALUE v)
{
  VALUE v_dbl = rb_check_float_type(v);
  return RTEST(v_dbl) ? NUM2DBL(v_dbl) : double(NUM2INT(v));
}

static inline double apply_contrast(double x, double contrast)
{
  const double r = 0.5 + (x - 0.5) * contrast;
//   fprintf(stderr, "apply_contrast %.6f x %.2f -> %.6f(%.6f)\n", x, contrast, r, r <= 0.0 ? 0.0 : r >= 1.0 ? 1.0 : r);
  return r <= 0.0 ? 0.0 : r >= 1.0 ? 1.0 : r;
}

/*
The main initialize function which recieves the inputs persistence and octave.
*/
static VALUE perlin_initialize(VALUE self, VALUE seed_value, VALUE persistence, VALUE octave,
                               VALUE smoothing, VALUE contrast)
{
  rb_iv_set(self, "@persistence", persistence);
//   fprintf(stderr, "Setting @persistence to %.4f\n", num2dbl(persistence));
  rb_iv_set(self, "@octave", octave);
  rb_iv_set(self, "@seed", seed_value);
  rb_iv_set(self, "@smoothing", smoothing);
  rb_iv_set(self, "@contrast", contrast);
  return self;
}

static inline double perlin_interpolate(const double a, const double b, const double x)
{
  const double ft = x * M_PI;
  const double f = (1 - cos(ft)) * 0.5;
  return  a * (1 - f) + b * f;
}

static int seed = 0; // set by run's to @seed!

// returns a predicatable result between 0.0 and 1.0.
static inline double perlin_noise(int x)
{
  x = (x << 13) ^ x;
  return 1.0 - double(unsigned((x * (x * x * 15731 * seed + 789221 * seed) + 1376312589 * seed))) / double(UINT_MAX);
}

static inline double perlin_noise(const int x, const int y)
{
  return perlin_noise(x + y * 57);
}

// the result is between 0.0 and 1.0
static inline double perlin_smooth_noise(int x)
{
  return perlin_noise(x) / 2  +  perlin_noise(x - 1) / 4  + perlin_noise(x + 1) / 4;
}

static double perlin_interpolated_noise(bool smoothing, double x)
{
  const int integer_X = int(x);
  const double fractional_X = x - integer_X;

  const double v1 = smoothing ? perlin_smooth_noise(integer_X) : perlin_noise(integer_X);
  const double v2 = smoothing ? perlin_smooth_noise(integer_X + 1) : perlin_noise(integer_X + 1);
  return perlin_interpolate(v1 , v2 , fractional_X);
}

static VALUE perlin_run1d(VALUE self, const VALUE x)
{
  const bool smoothing = RTEST(rb_iv_get(self, "@smoothing"));
  const int n = NUM2INT(rb_iv_get(self, "@octave"));
  seed = NUM2INT(rb_iv_get(self, "@seed"));
  const double x_f = num2dbl(x);
  const double contrast = num2dbl(rb_iv_get(self, "@contrast"));
  if (n == 1) // speed-up
    return DBL2NUM(apply_contrast(perlin_interpolated_noise(smoothing, x_f), contrast));
//   fprintf(stderr, "getting persistence\n");
  const double p = num2dbl(rb_iv_get(self, "@persistence"));
//   fprintf(stderr, "getting persistence %.4f\n", p);
  double total = 0, frequency = 1, amplitude = 1;
  double tot_amp = 0;

  for (int i = 0; i < n; i++, frequency *= 2, amplitude *= p)
    {
      total += perlin_interpolated_noise(smoothing, x_f * frequency) * amplitude;
      tot_amp += amplitude;
    }
  return DBL2NUM(apply_contrast(total / tot_amp, contrast)); // oops
}

// the result is between 0 and 1.0
static double perlin_smooth_noise(const int x, const int y)
{
  const double corners = (perlin_noise(x - 1, y - 1) + perlin_noise(x + 1, y - 1)
                          + perlin_noise(x - 1, y + 1) + perlin_noise(x + 1, y + 1)) / 16.0;
    // between 0.0 and 0.25
  const double sides   = (perlin_noise(x - 1, y) + perlin_noise(x + 1, y)
                          + perlin_noise(x, y - 1) + perlin_noise(x, y + 1)) /  8.0;
    // between 0.0 and 0.5
  const double center  =  perlin_noise(x, y) / 4.0;
    // between 0.0 and 0.25
  return corners + sides + center;
}

static double perlin_interpolated_noise(bool smoothing, const double x, const double y)
{
  const int integer_X = (int)x;
  const double fractional_X = x - integer_X;

  const int integer_Y = (int)y;
  const double fractional_Y = y - integer_Y;

  const double v1 = smoothing ? perlin_smooth_noise(integer_X, integer_Y)
                              : perlin_noise(integer_X, integer_Y);
  const double v2 = smoothing ? perlin_smooth_noise(integer_X + 1, integer_Y)
                              : perlin_noise(integer_X + 1, integer_Y);
  const double v3 = smoothing ? perlin_smooth_noise(integer_X, integer_Y + 1)
                              : perlin_noise(integer_X, integer_Y + 1);
  const double v4 = smoothing ? perlin_smooth_noise(integer_X + 1, integer_Y + 1)
                              : perlin_noise(integer_X + 1, integer_Y + 1);
  const double i1 = perlin_interpolate(v1, v2, fractional_X);
  const double i2 = perlin_interpolate(v3, v4, fractional_X);
  return perlin_interpolate(i1, i2, fractional_Y);
}

static inline double perlin_noise_3d(const int x, const int y, const int z)
{
  return perlin_noise(x + y + z * 57);
}

static double perlin_smooth_noise_3d(const int x, const int y, const int z)
{
  const double corners = (perlin_noise_3d(x - 1, y - 1, z + 1) + perlin_noise_3d(x + 1, y - 1, z + 1)
                          + perlin_noise_3d(x - 1, y + 1, z + 1) + perlin_noise_3d(x + 1, y + 1, z + 1)
                          + perlin_noise_3d(x - 1, y - 1, z - 1) + perlin_noise_3d(x + 1, y - 1, z - 1)
                          + perlin_noise_3d(x - 1, y + 1, z - 1) + perlin_noise_3d(x + 1, y + 1, z - 1)) / 32.0;  // 0.25 at most
  const double sides   = (perlin_noise_3d(x - 1, y, z + 1) + perlin_noise_3d(x + 1, y, z + 1)
                          + perlin_noise_3d(x, y - 1, z + 1) + perlin_noise_3d(x, y + 1, z + 1)
                          + perlin_noise_3d(x - 1, y, z - 1) + perlin_noise_3d(x + 1, y, z - 1)
                          + perlin_noise_3d(x, y - 1, z - 1) + perlin_noise_3d(x, y + 1, z - 1)
                          + perlin_noise_3d(x - 1, y - 1, z) + perlin_noise_3d(x + 1, y - 1, z)
                          + perlin_noise_3d(x + 1, y + 1, z) + perlin_noise_3d(x - 1, y + 1, z)) / 24.0; // 0.5 at most
  const double center = perlin_noise(x, y) / 4.0; // 0.25 at most
  return corners + sides + center;
}

static double perlin_interpolated_noise_3d(const double x, const double y, const double z)
{
  const int integer_X = (int)x;
  const double fractional_X = x - integer_X;

  const int integer_Y = (int)y;
  const double fractional_Y = y - integer_Y;

  const int integer_Z = (int)z;
  const double fractional_Z  = z - integer_Z;

  const double a = perlin_smooth_noise_3d(integer_X,     integer_Y, 	integer_Z);
  const double b = perlin_smooth_noise_3d(integer_X + 1, integer_Y, 	integer_Z);
  const double c = perlin_smooth_noise_3d(integer_X,     integer_Y + 1, integer_Z);
  const double d = perlin_smooth_noise_3d(integer_X,     integer_Y, 	integer_Z + 1);
  const double e = perlin_smooth_noise_3d(integer_X + 1, integer_Y + 1, integer_Z);
  const double f = perlin_smooth_noise_3d(integer_X,     integer_Y + 1, integer_Z + 1);
  const double g = perlin_smooth_noise_3d(integer_X + 1, integer_Y, 	integer_Z + 1);
  const double h = perlin_smooth_noise_3d(integer_X + 1, integer_Y + 1, integer_Z + 1);

  const double i1 = perlin_interpolate(a, b, fractional_X);
  const double i2 = perlin_interpolate(c, d, fractional_X);
  const double i3 = perlin_interpolate(e, f, fractional_X);
  const double i4 = perlin_interpolate(g, h, fractional_X);

  const double y1 = perlin_interpolate(i1, i2, fractional_Y);
  const double y2 = perlin_interpolate(i3, i4, fractional_Y);

  return perlin_interpolate(y1, y2, fractional_Z);
}

/*
Takes points (x, y) and returns a height (n)
*/
static VALUE perlin_run(VALUE self, const VALUE x, const VALUE y)
{
  seed = NUM2INT(rb_iv_get(self, "@seed"));
  const int n = NUM2INT(rb_iv_get(self, "@octave"));
  const double x_f = num2dbl(x), y_f = num2dbl(y);
  const double contrast = num2dbl(rb_iv_get(self, "@contrast"));
  const bool smoothing = RTEST(rb_iv_get(self, "@smoothing"));
  if (n == 1)
    return DBL2NUM(apply_contrast(perlin_interpolated_noise(smoothing, x_f, y_f), contrast));
  const double p = num2dbl(rb_iv_get(self, "@persistence"));
  double total = 0, frequency = 1, amplitude = 1, tot_amp = 0;
  for (int i = 0; i < n; ++i, frequency *= 2, amplitude *= p)
    {
      total += perlin_interpolated_noise(smoothing, x_f * frequency, y_f * frequency) * amplitude;
      tot_amp += amplitude;
    }
  return DBL2NUM(apply_contrast(total / tot_amp, contrast));
}

/*
Takes points (x, y, z) and returns a height (n)
IMPORTANT: smoothing is IGNORED!!!
*/
static VALUE perlin_run3d(VALUE self, const VALUE x, const VALUE y, const VALUE z)
{
  seed = NUM2INT(rb_iv_get(self, "@seed"));
  const int n = NUM2INT(rb_iv_get(self, "@octave"));
  const double x_f = num2dbl(x), y_f = num2dbl(y), z_f = num2dbl(z);
  const double contrast = num2dbl(rb_iv_get(self, "@contrast"));
  if (n == 1)
    return DBL2NUM(apply_contrast(perlin_interpolated_noise_3d(x_f, y_f, z_f), contrast));
  const double p = num2dbl(rb_iv_get(self, "@persistence"));
  double total = 0, tot_amp = 0;
  double frequency = 1, amplitude = 1;
  int i;
  for (i = 0; i < n; ++i, frequency *= 2, amplitude *= p)
    {
      total += perlin_interpolated_noise_3d(x_f * frequency, y_f * frequency, z_f * frequency) * amplitude;
      tot_amp += amplitude;
    }
  return DBL2NUM(apply_contrast(total / amplitude, contrast));
}

/*
Returns a chunk of coordinates start from start_x to size_x, and start_y to size_y.
*/
static VALUE perlin_return_chunk(VALUE self, VALUE start_x, VALUE start_y, VALUE size_x, VALUE size_y)
{
  VALUE arr = rb_ary_new();
  int i, j;
  for (i = NUM2INT(start_x); i < NUM2INT(size_x) + NUM2INT(start_x); i++)
    {
      VALUE row = rb_ary_new();
      rb_ary_push(arr, row);
      for (j = NUM2INT(start_y); j < NUM2INT(size_y) + NUM2INT(start_y); j++)
        rb_ary_push(row, perlin_run(self, INT2NUM(i), INT2NUM(j)));
    }
  return arr;
}

extern "C" void Init_perlin()
{
  rb_cPerlin = rb_define_class("Perlin", rb_cObject);
  rb_define_method(rb_cPerlin, "initialize", RUBY_METHOD_FUNC(perlin_initialize), 5);
  rb_define_method(rb_cPerlin, "run1d", RUBY_METHOD_FUNC(perlin_run1d), 1);
  rb_define_method(rb_cPerlin, "run2d", RUBY_METHOD_FUNC(perlin_run), 2);
  rb_define_method(rb_cPerlin, "run", RUBY_METHOD_FUNC(perlin_run), 2); // alias for run2d
  rb_define_method(rb_cPerlin, "run3d", RUBY_METHOD_FUNC(perlin_run3d), 3);
  rb_define_method(rb_cPerlin, "return_chunk", RUBY_METHOD_FUNC(perlin_return_chunk), 4);
}
