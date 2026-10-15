// Display-time unit conversions (plan/06 § Units). Storage stays in °F
// and inches; these only produce the metric values a screen shows.

/// °C for display: `(°F − 32) × 5/9`, rounded to an integer.
int fahrenheitToCelsiusDisplay(double fahrenheit) =>
    ((fahrenheit - 32) * 5 / 9).round();

/// mm for display: `in × 25.4`, rounded to 1 decimal.
double inchesToMillimetersDisplay(double inches) =>
    (inches * 25.4 * 10).round() / 10;
