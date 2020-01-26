// Licensed to the Apache Software Foundation (ASF) under one or more
// contributor license agreements.  See the NOTICE file distributed with
// this work for additional information regarding copyright ownership.
// The ASF licenses this file to You under the Apache License, Version 2.0
// (the "License"); you may not use this file except in compliance with
// the License.  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

library complex_type;

import 'dart:math' as math;
import 'fastmath.dart' as fastmath;

/// Representation of a complex number, i.e. a number which has both a
/// real and imaginary part.
///
/// Implementations of arithmetic operations handle `NaN` and
/// infinite values according to the rules for [double], i.e.
/// [==] is an equivalence relation for all instances that have
/// a `NaN` in either real or imaginary part, e.g. the following are
/// considered equal:
///
/// * `1 + NaNi`
/// * `NaN + i`
/// * `NaN + NaNi`
///
/// Note that this is in contradiction with the IEEE-754 standard for floating
/// point numbers (according to which the test `x == x` must fail if
/// `x` is `NaN`).
class Complex {
  /// The square root of -1. A number representing "0.0 + 1.0i"
  static const i = Complex._(0.0, 1.0);

  /// A complex number representing "NaN + NaNi"
  static const nan = Complex._(double.nan, double.nan);

  /// A complex number representing "+INF + INFi"
  static const infinity = Complex._(double.infinity, double.infinity);

  /// A complex number representing "1.0 + 0.0i"
  static const one = Complex._(1.0);

  /// A complex number representing "0.0 + 0.0i"
  static const zero = Complex._(0.0);

  final double _imaginary, _real;

  /// The imaginary part.
  double get imaginary => _imaginary;

  /// The real part.
  double get real => _real;

  /// Create a complex number given the real part and optionally the imaginary
  /// part.
  Complex(num real, [num imaginary = 0])
      : _real = real.toDouble(),
        _imaginary = imaginary.toDouble();

  const Complex._(this._real, [this._imaginary = 0.0]);

  /// Creates a complex number from the given polar representation.
  ///
  /// The value returned is `r·e^(i·theta)`,
  /// computed as `r·cos(theta) + r·sin(theta)i`
  ///
  /// If either [r] or [theta] is `NaN`, or
  /// [theta] is infinite, [Complex.nan] is returned.
  ///
  /// If [r] is infinite and [theta] is finite,
  /// infinite or NaN values may be returned in parts of the result, following
  /// the rules for double arithmetic.
  ///
  /// If [radians] is `false` then [theta] is converted from degrees to
  /// radians.
  ///
  /// Examples:
  ///
  ///     polar(INFINITY, π/4) = INFINITY + INFINITY i
  ///     polar(INFINITY, 0) = INFINITY + NaN i
  ///     polar(INFINITY, -π/4) = INFINITY - INFINITY i
  ///     polar(INFINITY, 5π/4) = -INFINITY - INFINITY i
  factory Complex.polar(num r, num theta, [bool radians = true]) {
    r = r.toDouble();
    theta = theta.toDouble();
    if (!radians) {
      theta = theta * math.pi / 180.0;
    }
    if (r < 0) {
      throw ArgumentError('Negative complex modulus: $r');
    }
    return Complex(r * math.cos(theta), r * math.sin(theta));
  }

  /// True if the real and imaginary parts are finite; otherwise, false.
  bool get isFinite => !isNaN && _real.isFinite && _imaginary.isFinite;

  /// True if the real and imaginary parts are positive infinity or negative
  /// infinity; otherwise, false.
  bool get isInfinite => !isNaN && (_real.isInfinite || _imaginary.isInfinite);

  /// True if the real and imaginary parts are the double Not-a-Number value;
  /// otherwise, false.
  bool get isNaN => _real.isNaN || _imaginary.isNaN;

  /// Return the absolute value of this complex number.
  /// Returns `NaN` if either real or imaginary part is `NaN`
  /// and `double.INFINITY` if neither part is `NaN`,
  /// but at least one part is infinite.
  double abs() {
    if (isNaN) {
      return double.nan;
    }
    if (isInfinite) {
      return double.infinity;
    }
    if (_real.abs() < _imaginary.abs()) {
      if (_real == 0.0) {
        return _imaginary.abs();
      }
      double q = _real / _imaginary;
      return _imaginary.abs() * math.sqrt(1 + q * q);
    } else {
      if (_imaginary == 0.0) {
        return _real.abs();
      }
      double q = _imaginary / _real;
      return _real.abs() * math.sqrt(1 + q * q);
    }
  }

  /// Returns a `Complex` whose value is
  /// `(this + addend)`.
  /// Uses the definitional formula
  ///
  ///     (a + bi) + (c + di) = (a+c) + (b+d)i
  ///
  /// If either `this` or [addend] has a `NaN` value in
  /// either part, [NaN] is returned; otherwise `Infinite`
  /// and `NaN` values are returned in the parts of the result
  /// according to the rules for [double] arithmetic.
  Complex operator +(Object addend) {
    if (addend is Complex) {
      if (isNaN || addend.isNaN) {
        return Complex.nan;
      }
      return Complex._(_real + addend.real, _imaginary + addend.imaginary);
    } else if (addend is num) {
      if (isNaN || addend.isNaN) {
        return Complex.nan;
      }
      return Complex._(_real + addend, _imaginary);
    } else {
      throw ArgumentError('factor must be a num or a Complex');
    }
  }

  /// Return the conjugate of this complex number.
  /// The conjugate of `a + bi` is `a - bi`.
  ///
  /// [NaN] is returned if either the real or imaginary
  /// part of this Complex number equals `double.nan`.
  ///
  /// If the imaginary part is infinite, and the real part is not
  /// `NaN`, the returned value has infinite imaginary part
  /// of the opposite sign, e.g. the conjugate of
  /// `1 + INFINITY i is `1 - NEGATIVE_INFINITY i`.
  Complex conjugate() {
    if (isNaN) {
      return Complex.nan;
    }
    return Complex._(real, -imaginary);
  }

  /// Returns a `Complex` whose value is
  /// `(this / divisor)`.
  /// Implements the definitional formula
  ///
  ///       a + bi       ac + bd + (bc - ad)i
  ///     ---------- = ------------------------
  ///       c + di           c^2 + d^2
  ///
  /// but uses [prescaling of operands](http://doi.acm.org/10.1145/1039813.1039814)
  /// to limit the effects of overflows and underflows in the computation.
  ///
  /// `Infinite` and `NaN` values are handled according to the
  /// following rules, applied in the order presented:
  ///
  /// * If either `this` or `divisor` has a `NaN` value
  ///   in either part, [nan] is returned.
  /// * If `divisor` equals [zero], [nan] is returned.
  /// * If `this` and `divisor` are both infinite,
  ///   [nan] is returned.
  /// * If `this` is finite (i.e., has no `Infinite` or
  ///   `NAN` parts) and `divisor` is infinite (one or both parts
  ///   infinite), [zero] is returned.
  /// * If `this` is infinite and `divisor` is finite,
  /// `NAN` values are returned in the parts of the result if the
  /// [double] rules applied to the definitional formula
  /// force `NaN` results.
  Complex operator /(Object divisor) {
    if (divisor is Complex) {
      if (isNaN || divisor.isNaN) {
        return nan;
      }

      final double c = divisor.real;
      final double d = divisor.imaginary;
      if (c == 0.0 && d == 0.0) {
        return nan;
      }

      if (divisor.isInfinite && !isInfinite) {
        return zero;
      }

      if (c.abs() < d.abs()) {
        double q = c / d;
        double denominator = c * q + d;
        return Complex._((_real * q + _imaginary) / denominator,
            (_imaginary * q - _real) / denominator);
      } else {
        double q = d / c;
        double denominator = d * q + c;
        return Complex._((_imaginary * q + _real) / denominator,
            (_imaginary - _real * q) / denominator);
      }
    } else if (divisor is num) {
      if (isNaN || divisor.isNaN) {
        return nan;
      }
      if (divisor == 0) {
        return nan;
      }
      if (divisor.isInfinite) {
        return isFinite ? zero : nan;
      }
      return Complex._(_real / divisor, _imaginary / divisor);
    } else {
      throw ArgumentError('factor must be a num or a Complex');
    }
  }

  /// Returns the multiplicative inverse of `this` element.
  Complex reciprocal() {
    if (isNaN) {
      return nan;
    }

    if (_real == 0.0 && _imaginary == 0.0) {
      return infinity;
    }

    if (isInfinite) {
      return zero;
    }

    if (_real.abs() < _imaginary.abs()) {
      double q = _real / _imaginary;
      double scale = 1.0 / (_real * q + _imaginary);
      return Complex._(scale * q, -scale);
    } else {
      double q = _imaginary / _real;
      double scale = 1.0 / (_imaginary * q + _real);
      return Complex._(scale, -scale * q);
    }
  }

  /// Test for equality with another object.
  ///
  /// If both the real and imaginary parts of two complex numbers
  /// are exactly the same, and neither is `double.nan`, the two
  /// Complex objects are considered to be equal.
  ///
  /// * All `NaN` values are considered to be equal,
  ///   i.e, if either (or both) real and imaginary parts of the complex
  ///   number are equal to `double.nan`, the complex number is equal
  ///   to `NaN`.
  /// * Instances constructed with different representations of zero (i.e.
  ///   either "0" or "-0") are *not* considered to be equal.
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is Complex) {
      Complex c = other;
      if (c.isNaN) {
        return isNaN;
      } else {
        return _real == c.real && _imaginary == c.imaginary;
      }
    }
    return false;
  }

  /// Returns a `Complex` whose value is `this * factor`.
  /// Implements preliminary checks for `NaN` and infinity followed by
  /// the definitional formula:
  ///
  ///     (a + bi)(c + di) = (ac - bd) + (ad + bc)i
  ///
  /// Returns [nan] if either `this` or `factor` has one or
  /// more `NaN` parts.
  ///
  /// Returns [infinity] if neither `this` nor `factor` has one
  /// or more `NaN` parts and if either `this` or `factor`
  /// has one or more infinite parts (same result is returned regardless of
  /// the sign of the components).
  ///
  /// Returns finite values in components of the result per the definitional
  /// formula in all remaining cases.
  Complex operator *(Object factor) {
    if (factor is Complex) {
      if (isNaN || factor.isNaN) {
        return nan;
      }
      if (_real.isInfinite ||
          _imaginary.isInfinite ||
          factor._real.isInfinite ||
          factor._imaginary.isInfinite) {
        // we don't use isInfinite to avoid testing for NaN again
        return infinity;
      }
      return Complex._(_real * factor._real - _imaginary * factor._imaginary,
          _real * factor._imaginary + _imaginary * factor._real);
    } else if (factor is num) {
      if (isNaN || factor.isNaN) {
        return nan;
      }
      if (_real.isInfinite || _imaginary.isInfinite || factor.isInfinite) {
        // we don't use isInfinite to avoid testing for NaN again
        return infinity;
      }
      return Complex._(_real * factor, _imaginary * factor);
    } else {
      throw ArgumentError('factor must be a num or a Complex');
    }
  }

  /// Negate operator. Returns a `Complex` whose value is `-this`.
  /// Returns `NAN` if either real or imaginary
  /// part of this complex number equals `double.nan`.
  Complex operator -() {
    if (isNaN) {
      return nan;
    }

    return Complex._(-_real, -_imaginary);
  }

  /// Returns a `Complex` whose value is
  /// `this - subtrahend`.
  /// Uses the definitional formula
  ///
  ///     (a + bi) - (c + di) = (a-c) + (b-d)i
  ///
  /// If either `this` or `subtrahend` has a `NaN` value in either part,
  /// [nan] is returned; otherwise infinite and `NaN` values are
  /// returned in the parts of the result according to the rules for
  /// [double] arithmetic.
  Complex operator -(Object subtrahend) {
    if (subtrahend is Complex) {
      if (isNaN || subtrahend.isNaN) {
        return nan;
      }

      return Complex._(
          real - subtrahend._real, imaginary - subtrahend._imaginary);
    } else if (subtrahend is num) {
      if (isNaN || subtrahend.isNaN) {
        return nan;
      }
      return Complex._(real - subtrahend, imaginary);
    } else {
      throw ArgumentError('factor must be a num or a Complex');
    }
  }

  /// Compute the [inverse cosine](http://mathworld.wolfram.com/InverseCosine.html)
  /// of this complex number.
  ///
  /// Implements the formula:
  ///
  ///     acos(z) = -i (log(z + i (sqrt(1 - z^2))))
  ///
  /// Returns [nan] if either real or imaginary part of the
  /// input argument is `NaN` or infinite.
  Complex acos() {
    if (isNaN) {
      return nan;
    }
    return (this + (this.sqrt1z() * i)).log() * (-i);
  }

  /// Compute the [inverse sine](http://mathworld.wolfram.com/InverseSine.html)
  /// of this complex number.
  ///
  /// Implements the formula:
  ///
  ///     asin(z) = -i (log(sqrt(1 - z^2) + iz))
  ///
  /// Returns [nan] if either real or imaginary part of the
  /// input argument is `NaN` or infinite.
  Complex asin() {
    if (isNaN) {
      return nan;
    }

    return (sqrt1z() + (this * i)).log() * -i;
  }

  /// Compute the [inverse tangent](http://mathworld.wolfram.com/InverseTangent.html)
  /// of this complex number.
  ///
  /// Implements the formula:
  ///
  ///     atan(z) = (i/2) log((i + z)/(i - z))
  ///
  /// Returns [nan] if either real or imaginary part of the
  /// input argument is `NaN` or infinite.
  Complex atan() {
    if (isNaN) {
      return nan;
    }

    return ((this + i) / (i - this)).log() * (i / Complex._(2.0, 0.0));
  }

  /// Compute the [cosine](http://mathworld.wolfram.com/Cosine.html)
  /// of this complex number.
  ///
  /// Implements the formula:
  ///
  ///     cos(a + bi) = cos(a)cosh(b) - sin(a)sinh(b)i
  ///
  /// where the (real) functions on the right-hand side are
  /// [math.sin], [math.cos], [fastmath.cosh] and [fastmath.sinh].
  ///
  /// Returns [nan] if either real or imaginary part of the
  /// input argument is `NaN`.
  ///
  /// Infinite values in real or imaginary parts of the input may result in
  /// infinite or `NaN` values returned in parts of the result.
  ///
  /// Examples:
  ///
  ///     cos(1 ± INFINITY i) = 1 ∓ INFINITY i
  ///     cos(±INFINITY + i) = NaN + NaN i
  ///     cos(±INFINITY ± INFINITY i) = NaN + NaN i
  Complex cos() {
    if (isNaN) {
      return nan;
    }

    return Complex._(math.cos(real) * fastmath.cosh(imaginary),
        -math.sin(real) * fastmath.sinh(imaginary));
  }

  /// Compute the [hyperbolic cosine](http://mathworld.wolfram.com/HyperbolicCosine.html)
  /// of this complex number.
  ///
  /// Implements the formula:
  ///
  ///     cosh(a + bi) = cosh(a)cos(b) + sinh(a)sin(b)i
  ///
  /// where the (real) functions on the right-hand side are
  /// [math.sin], [math.cos], [fastmath.cosh] and [fastmath.sinh].
  ///
  /// Returns [nan] if either real or imaginary part of the
  /// input argument is `NaN`.
  ///
  /// Infinite values in real or imaginary parts of the input may result in
  /// infinite or NaN values returned in parts of the result.
  ///
  /// Examples:
  ///
  ///     cosh(1 ± INFINITY i) = NaN + NaN i
  ///     cosh(±INFINITY + i) = INFINITY ± INFINITY i
  ///     cosh±INFINITY &plusmn; INFINITY i) = NaN + NaN i
  Complex cosh() {
    if (isNaN) {
      return nan;
    }

    return Complex._(fastmath.cosh(real) * math.cos(imaginary),
        fastmath.sinh(real) * math.sin(imaginary));
  }

  /// Compute the [exponential function](http://mathworld.wolfram.com/ExponentialFunction.html)
  /// of this complex number.
  ///
  /// Implements the formula:
  ///
  ///     exp(a + bi) = exp(a)cos(b) + exp(a)sin(b)i
  ///
  /// where the (real) functions on the right-hand side are
  /// [math.exp], [math.cos], and [math.sin].
  ///
  /// Returns [nan] if either real or imaginary part of the
  /// input argument is `NaN`.
  ///
  /// Infinite values in real or imaginary parts of the input may result in
  /// infinite or `NaN` values returned in parts of the result.
  ///
  /// Examples:
  ///
  ///     exp(1 ± INFINITY i) = NaN + NaN i
  ///     exp(INFINITY + i) = INFINITY + INFINITY i
  ///     exp(-INFINITY + i) = 0 + 0i
  ///     exp(±INFINITY ± INFINITY i) = NaN + NaN i
  Complex exp() {
    if (isNaN) {
      return nan;
    }

    double expReal = math.exp(real);
    return Complex._(
        expReal * math.cos(imaginary), expReal * math.sin(imaginary));
  }

  /// Compute the [natural logarithm](http://mathworld.wolfram.com/NaturalLogarithm.html)
  /// of this complex number.
  ///
  /// Implements the formula:
  ///
  ///     log(a + bi) = ln(|a + bi|) + arg(a + bi)i
  ///
  /// where ln on the right hand side is [math.log],
  /// `|a + bi|` is the modulus, [abs],  and
  /// `arg(a + bi) = atan2(b, a).
  ///
  /// Returns [nan] if either real or imaginary part of the
  /// input argument is `NaN`.
  ///
  /// Infinite (or critical) values in real or imaginary parts of the input may
  /// result in infinite or NaN values returned in parts of the result.
  ///
  /// Examples:
  ///
  ///     log(1 ± INFINITY i) = INFINITY ± (π/2)i
  ///     log(INFINITY + i) = INFINITY + 0i
  ///     log(-INFINITY + i) = INFINITY + &pi;i
  ///     log(INFINITY ± INFINITY i) = INFINITY ± (π/4)i
  ///     log(-INFINITY ± INFINITY i) = INFINITY ± (3π/4)i
  ///     log(0 + 0i) = -INFINITY + 0i
  Complex log() {
    if (isNaN) {
      return nan;
    }

    return Complex._(math.log(abs()), fastmath.atan2(imaginary, real));
  }

  /// Returns of value of this complex number raised to the power of `x`.
  ///
  /// Implements the formula:
  ///
  ///     y^x = exp(x·log(y))
  ///
  /// where `exp` and `log` are [exp] and
  /// [log], respectively.
  ///
  /// Returns [nan] if either real or imaginary part of the
  /// input argument is `NaN` or infinite, or if `y`
  /// equals [zero].
  Complex power(Complex x) {
    return (this.log() * x).exp();
  }

  /// Returns of value of this complex number raised to the power of `x`.
  Complex pow(num x) {
    return (this.log() * x).exp();
  }

  /// Compute the [sine](http://mathworld.wolfram.com/Sine.html)
  /// of this complex number.
  ///
  /// Implements the formula:
  ///
  ///     sin(a + bi) = sin(a)cosh(b) - cos(a)sinh(b)i
  ///
  /// where the (real) functions on the right-hand side are
  /// [math.sin], [math.cos], [fastmath.cosh] and [fastmath.sinh].
  ///
  /// Returns [nan] if either real or imaginary part of the
  /// input argument is `NaN`.
  ///
  /// Infinite values in real or imaginary parts of the input may result in
  /// infinite or `NaN` values returned in parts of the result.
  ///
  /// Examples:
  ///
  ///     sin(1 ± INFINITY i) = 1 ± INFINITY i
  ///     sin(±INFINITY + i) = NaN + NaN i
  ///     sin(±INFINITY ± INFINITY i) = NaN + NaN i
  Complex sin() {
    if (isNaN) {
      return nan;
    }

    return Complex._(math.sin(real) * fastmath.cosh(imaginary),
        math.cos(real) * fastmath.sinh(imaginary));
  }

  /// Compute the [hyperbolic sine](http://mathworld.wolfram.com/HyperbolicSine.html)
  /// of this complex number.
  ///
  /// Implements the formula:
  ///
  ///     sinh(a + bi) = sinh(a)cos(b)) + cosh(a)sin(b)i
  ///
  /// where the (real) functions on the right-hand side are
  /// [math.sin], [math.cos], [fastmath.cosh] and [fastmath.sinh].
  ///
  /// Returns [nan] if either real or imaginary part of the
  /// input argument is `NaN`.
  ///
  /// Infinite values in real or imaginary parts of the input may result in
  /// infinite or NaN values returned in parts of the result.
  ///
  /// Examples:
  ///
  ///     sinh(1 ± INFINITY i) = NaN + NaN i
  ///     sinh(±INFINITY + i) = ± INFINITY + INFINITY i
  ///     sinh(±INFINITY ± INFINITY i) = NaN + NaN i
  Complex sinh() {
    if (isNaN) {
      return nan;
    }

    return Complex._(fastmath.sinh(real) * math.cos(imaginary),
        fastmath.cosh(real) * math.sin(imaginary));
  }

  /// Compute the [square root](http://mathworld.wolfram.com/SquareRoot.html)
  /// of this complex number.
  ///
  /// Implements the following algorithm to compute `sqrt(a + bi)}:
  ///
  /// 1. Let `t = sqrt((|a| + |a + bi|) / 2)`
  /// 2. if `a ≥ 0` return `t + (b/2t)i`
  ///    else return `|b|/2t + sign(b)t i`
  ///
  /// where:
  ///
  /// * `|a| = abs(a)`
  /// * `|a + bi| = abs(a + bi)`
  /// * `sign(b) = copySign(double, double) copySign(1d, b)`
  ///
  /// Returns [nan] if either real or imaginary part of the
  /// input argument is `NaN`.
  ///
  /// Infinite values in real or imaginary parts of the input may result in
  /// infinite or NaN values returned in parts of the result.
  ///
  /// Examples:
  ///
  ///     sqrt(1 ± INFINITY i) = INFINITY + NaN i
  ///     sqrt(INFINITY + i) = INFINITY + 0i
  ///     sqrt(-INFINITY + i) = 0 + INFINITY i
  ///     sqrt(INFINITY ± INFINITY i) = INFINITY + NaN i
  ///     sqrt(-INFINITY ± INFINITY i) = NaN ± INFINITY i
  Complex sqrt() {
    if (isNaN) {
      return nan;
    }

    if (real == 0.0 && imaginary == 0.0) {
      return Complex._(0.0, 0.0);
    }

    double t = math.sqrt((real.abs() + abs()) / 2.0);
    if (real >= 0.0) {
      return Complex._(t, imaginary / (2.0 * t));
    } else {
      return Complex._(
          imaginary.abs() / (2.0 * t), fastmath.copySign(1.0, imaginary) * t);
    }
  }

  /// Compute the [square root](http://mathworld.wolfram.com/SquareRoot.html)
  /// of `1 - this^2` for this complex number.
  ///
  /// Computes the result directly as `sqrt(ONE - (z * z))`.
  ///
  /// Returns [nan] if either real or imaginary part of the
  /// input argument is `NaN`.
  ///
  /// Infinite values in real or imaginary parts of the input may result in
  /// infinite or NaN values returned in parts of the result.
  Complex sqrt1z() {
    return (Complex._(1.0, 0.0) - (this * this)).sqrt();
  }

  /// Compute the [tangent](http://mathworld.wolfram.com/Tangent.html)
  /// of this complex number.
  ///
  /// Implements the formula:
  ///
  ///     tan(a + bi) = sin(2a)/(cos(2a)+cosh(2b)) + [sinh(2b)/(cos(2a)+cosh(2b))]i
  ///
  /// where the (real) functions on the right-hand side are
  /// [math.sin], [math.cos], [fastmath.cosh] and [fastmath.sinh].
  ///
  /// Returns [nan] if either real or imaginary part of the
  /// input argument is `NaN`.
  ///
  /// Infinite (or critical) values in real or imaginary parts of the input may
  /// result in infinite or `NaN` values returned in parts of the result.
  ///
  /// Examples:
  ///
  ///     tan(a ± INFINITY i) = 0 ± i
  ///     tan(±INFINITY + bi) = NaN + NaN i
  ///     tan(±INFINITY ± INFINITY i) = NaN + NaN i
  ///     tan(±π/2 + 0 i) = ±INFINITY + NaN i
  Complex tan() {
    if (isNaN || real.isInfinite) {
      return nan;
    }
    if (imaginary > 20.0) {
      return Complex._(0.0, 1.0);
    }
    if (imaginary < -20.0) {
      return Complex._(0.0, -1.0);
    }

    double real2 = 2.0 * real;
    double imaginary2 = 2.0 * imaginary;
    double d = math.cos(real2) + fastmath.cosh(imaginary2);

    return Complex._(math.sin(real2) / d, fastmath.sinh(imaginary2) / d);
  }

  /// Compute the [hyperbolic tangent](http://mathworld.wolfram.com/HyperbolicTangent.html)
  /// of this complex number.
  ///
  /// Implements the formula:
  ///
  ///     tan(a + bi) = sinh(2a)/(cosh(2a)+cos(2b)) + [sin(2b)/(cosh(2a)+cos(2b))]i
  ///
  /// where the (real) functions on the right-hand side are
  /// [math.sin], [math.cos], [fastmath.cosh] and [fastmath.sinh].
  ///
  /// Returns [nan] if either real or imaginary part of the
  /// input argument is `NaN`.
  ///
  /// Infinite values in real or imaginary parts of the input may result in
  /// infinite or NaN values returned in parts of the result.
  ///
  /// Examples:
  ///
  ///     tanh(a ± INFINITY i) = NaN + NaN i
  ///     tanh(±INFINITY + bi) = ±1 + 0 i
  ///     tanh(±INFINITY ± INFINITY i) = NaN + NaN i
  ///     tanh(0 + (π/2)i) = NaN + INFINITY i
  Complex tanh() {
    if (isNaN || imaginary.isInfinite) {
      return nan;
    }
    if (real > 20.0) {
      return Complex._(1.0, 0.0);
    }
    if (real < -20.0) {
      return Complex._(-1.0, 0.0);
    }
    double real2 = 2.0 * real;
    double imaginary2 = 2.0 * imaginary;
    double d = fastmath.cosh(real2) + math.cos(imaginary2);

    return Complex._(fastmath.sinh(real2) / d, math.sin(imaginary2) / d);
  }

  /// Compute the argument of this complex number.
  ///
  /// The argument is the angle phi between the positive real axis and
  /// the point representing this number in the complex plane.
  /// The value returned is between -PI (not inclusive)
  /// and PI (inclusive), with negative values returned for numbers with
  /// negative imaginary parts.
  ///
  /// If either real or imaginary part (or both) is NaN, NaN is returned.
  /// Infinite parts are handled as `Math.atan2} handles them,
  /// essentially treating finite parts as zero in the presence of an
  /// infinite coordinate and returning a multiple of pi/4 depending on
  /// the signs of the infinite parts.
  double argument() {
    return fastmath.atan2(imaginary, real);
  }

  /// Computes the n-th roots of this complex number.
  ///
  /// The nth roots are defined by the formula:
  ///
  ///     z_k = abs^(1/n) (cos(phi + 2πk/n) + i (sin(phi + 2πk/n))
  ///
  /// for `k=0, 1, ..., n-1`, where `abs` and `phi`
  /// are respectively the modulus and argument of this complex number.
  ///
  /// If one or both parts of this complex number is NaN, a list with just
  /// one element, [nan] is returned.
  /// If neither part is `NaN`, but at least one part is infinite, the result
  /// is a one-element list containing [infinity].
  List<Complex> nthRoot(int n) {
    if (n <= 0) {
      throw ArgumentError("Can't compute nth root for negative n");
    }

    final result = List<Complex>();

    if (isNaN) {
      result.add(nan);
      return result;
    }
    if (isInfinite) {
      result.add(infinity);
      return result;
    }

    // nth root of abs -- faster / more accurate to use a solver here?
    final double nthRootOfAbs = math.pow(abs(), 1.0 / n);

    // Compute nth roots of complex number with k = 0, 1, ... n-1
    final double nthPhi = argument() / n;
    final double slice = 2 * math.pi / n;
    double innerPart = nthPhi;
    for (int k = 0; k < n; k++) {
      // inner part
      final double realPart = nthRootOfAbs * math.cos(innerPart);
      final double imaginaryPart = nthRootOfAbs * math.sin(innerPart);
      result.add(Complex._(realPart, imaginaryPart));
      innerPart += slice;
    }

    return result;
  }

  /// Get a hashCode for the complex number.
  ///
  /// Any [double.nan] value in real or imaginary part produces
  /// the same hash code `7`.
  int get hashCode {
    if (isNaN) {
      return 7;
    }
    return 37 * (17 * _imaginary.hashCode + _real.hashCode);
  }

  String toString() {
    return "($real, $imaginary)";
  }
}
