import 'package:flutter/material.dart';
import 'package:scrollable_clean_calendar/controllers/clean_calendar_controller.dart';
import 'package:scrollable_clean_calendar/models/day_values_model.dart';
import 'package:scrollable_clean_calendar/utils/enums.dart';
import 'package:scrollable_clean_calendar/utils/extensions.dart';

class DaysWidget extends StatelessWidget {
  final CleanCalendarController cleanCalendarController;
  final DateTime month;
  final double calendarCrossAxisSpacing;
  final double calendarMainAxisSpacing;
  final Layout? layout;
  final bool showWeeksCount;

  /// A builder to make a customized week number of calendar
  final Widget Function(BuildContext context, int weekNumber)?
      weekNumberBuilder;

  final Widget Function(
    BuildContext context,
    DayValues values,
  )? dayBuilder;
  final Color? selectedBackgroundColor;
  final Color? backgroundColor;
  final Color? selectedBackgroundColorBetween;
  final Color? disableBackgroundColor;
  final Color? dayDisableColor;
  final double radius;
  final TextStyle? textStyle;

  const DaysWidget({
    Key? key,
    required this.month,
    required this.cleanCalendarController,
    required this.calendarCrossAxisSpacing,
    required this.calendarMainAxisSpacing,
    required this.layout,
    required this.dayBuilder,
    required this.selectedBackgroundColor,
    required this.backgroundColor,
    required this.selectedBackgroundColorBetween,
    required this.disableBackgroundColor,
    required this.dayDisableColor,
    required this.radius,
    required this.textStyle,
    required this.showWeeksCount,
    this.weekNumberBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Start weekday - Days per week - The first weekday of this month
    // 7 - 7 - 1 = -1 = 1
    // 6 - 7 - 1 = -2 = 2

    // What it means? The first weekday does not change, but the start weekday have changed,
    // so in the layout we need to change where the calendar first day is going to start.
    int monthPositionStartDay = (cleanCalendarController.weekdayStart -
            DateTime.daysPerWeek -
            DateTime(month.year, month.month).weekday)
        .abs();
    monthPositionStartDay = monthPositionStartDay > DateTime.daysPerWeek
        ? monthPositionStartDay - DateTime.daysPerWeek
        : monthPositionStartDay;

    final start = monthPositionStartDay == 7 ? 0 : monthPositionStartDay;

    // If the monthPositionStartDay is equal to 7, then in this layout logic will cause a trouble, beacause it will
    // have a line in blank and in this case 7 is the same as 0.
    int calculateRows(int year, int month) {
      DateTime firstDayOfMonth = DateTime(year, month, 1);
      DateTime lastDayOfMonth = DateTime(year, month + 1, 0);

      int firstWeekdayOfMonth = firstDayOfMonth.weekday;

      // Compute the number of cells to be filled in the calendar
      int numberOfCells = lastDayOfMonth.day + firstWeekdayOfMonth - 1;

      // Return the number of rows by dividing cells by 7 and rounding up
      return (numberOfCells / 7).ceil();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // left week numbers
        if (showWeeksCount)
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Column(
              children: [
                if (weekNumberBuilder != null)
                  for (int i = 0;
                      i < calculateRows(month.year, month.month);
                      i++)
                    SizedBox(
                      width: 44,
                      height: 48.7,
                      child: Align(
                        alignment: Alignment.center,
                        child: weekNumberBuilder!(
                            context, ((i + 1) + (month.month * 4))),
                      ),
                    )
                else
                  for (int i = 0;
                      i < calculateRows(month.year, month.month);
                      i++)
                    _WeeksNumberCount(
                      weekNumber: ((i + 1) + (month.month * 4)),
                    ),
              ],
            ),
          ),

        Expanded(
          child: GridView.count(
            crossAxisCount: DateTime.daysPerWeek,
            physics: const NeverScrollableScrollPhysics(),
            addRepaintBoundaries: false,
            padding: EdgeInsets.zero,
            crossAxisSpacing: calendarCrossAxisSpacing,
            mainAxisSpacing: calendarMainAxisSpacing,
            shrinkWrap: true,
            children: List.generate(
                DateTime(month.year, month.month + 1, 0).day + start, (index) {
              if (index < start) return const SizedBox.shrink();
              final day =
                  DateTime(month.year, month.month, (index + 1 - start));
              final text = (index + 1 - start).toString();

              bool isSelected = false;

              if (cleanCalendarController.rangeMinDate != null) {
                if (cleanCalendarController.rangeMinDate != null &&
                    cleanCalendarController.rangeMaxDate != null) {
                  isSelected = day.isSameDayOrAfter(
                          cleanCalendarController.rangeMinDate!) &&
                      day.isSameDayOrBefore(
                          cleanCalendarController.rangeMaxDate!);
                } else {
                  isSelected = day
                      .isAtSameMomentAs(cleanCalendarController.rangeMinDate!);
                }
              }

              Widget widget;

              final dayValues = DayValues(
                day: day,
                isFirstDayOfWeek:
                    day.weekday == cleanCalendarController.weekdayStart,
                isLastDayOfWeek:
                    day.weekday == cleanCalendarController.weekdayEnd,
                isSelected: isSelected,
                maxDate: cleanCalendarController.maxDate,
                minDate: cleanCalendarController.minDate,
                text: text,
                selectedMaxDate: cleanCalendarController.rangeMaxDate,
                selectedMinDate: cleanCalendarController.rangeMinDate,
              );

              if (dayBuilder != null) {
                widget = dayBuilder!(context, dayValues);
              } else {
                widget = <Layout, Widget Function()>{
                  Layout.DEFAULT: () => _pattern(context, dayValues),
                  Layout.BEAUTY: () => _beauty(context, dayValues),
                }[layout]!();
              }

              return GestureDetector(
                onTap: () {
                  if (day.isBefore(cleanCalendarController.minDate) &&
                      !day.isSameDay(cleanCalendarController.minDate)) {
                    if (cleanCalendarController.onPreviousMinDateTapped !=
                        null) {
                      cleanCalendarController.onPreviousMinDateTapped!(day);
                    }
                  } else if (day.isAfter(cleanCalendarController.maxDate)) {
                    if (cleanCalendarController.onAfterMaxDateTapped != null) {
                      cleanCalendarController.onAfterMaxDateTapped!(day);
                    }
                  } else {
                    if (!cleanCalendarController.readOnly) {
                      cleanCalendarController.onDayClick(day);
                    }
                  }
                },
                child: widget,
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _pattern(BuildContext context, DayValues values) {
    Color bgColor = backgroundColor ?? Theme.of(context).colorScheme.surface;
    TextStyle txtStyle =
        (textStyle ?? Theme.of(context).textTheme.bodyLarge)!.copyWith(
      color: backgroundColor != null
          ? backgroundColor!.computeLuminance() > .5
              ? Colors.black
              : Colors.white
          : Theme.of(context).colorScheme.onSurface,
    );

    if (values.isSelected) {
      if ((values.selectedMinDate != null &&
              values.day.isSameDay(values.selectedMinDate!)) ||
          (values.selectedMaxDate != null &&
              values.day.isSameDay(values.selectedMaxDate!))) {
        bgColor =
            selectedBackgroundColor ?? Theme.of(context).colorScheme.primary;
        txtStyle =
            (textStyle ?? Theme.of(context).textTheme.bodyLarge)!.copyWith(
          color: selectedBackgroundColor != null
              ? selectedBackgroundColor!.computeLuminance() > .5
                  ? Colors.black
                  : Colors.white
              : Theme.of(context).colorScheme.onPrimary,
        );
      } else {
        bgColor = selectedBackgroundColorBetween ??
            Theme.of(context).colorScheme.primary.withOpacity(.3);
        txtStyle =
            (textStyle ?? Theme.of(context).textTheme.bodyLarge)!.copyWith(
          color: selectedBackgroundColor != null &&
                  selectedBackgroundColor == selectedBackgroundColorBetween
              ? selectedBackgroundColor!.computeLuminance() > .5
                  ? Colors.black
                  : Colors.white
              : selectedBackgroundColor ??
                  Theme.of(context).colorScheme.primary,
        );
      }
    } else if (values.day.isSameDay(values.minDate)) {
      bgColor = Colors.transparent;
      txtStyle = (textStyle ?? Theme.of(context).textTheme.bodyLarge)!.copyWith(
        color: selectedBackgroundColor ?? Theme.of(context).colorScheme.primary,
      );
    } else if (values.day.isBefore(values.minDate) ||
        values.day.isAfter(values.maxDate)) {
      bgColor = disableBackgroundColor ??
          Theme.of(context).colorScheme.surface.withOpacity(.4);
      txtStyle = (textStyle ?? Theme.of(context).textTheme.bodyLarge)!.copyWith(
        color: dayDisableColor ??
            Theme.of(context).colorScheme.onSurface.withOpacity(.5),
        decoration: TextDecoration.lineThrough,
      );
    }

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(radius),
        border: values.day.isSameDay(values.minDate)
            ? Border.all(
                color: selectedBackgroundColor ??
                    Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : null,
      ),
      child: Text(
        values.text,
        textAlign: TextAlign.center,
        style: txtStyle,
      ),
    );
  }

  Widget _beauty(BuildContext context, DayValues values) {
    BorderRadiusGeometry? borderRadius;
    Color bgColor = Colors.transparent;
    TextStyle txtStyle =
        (textStyle ?? Theme.of(context).textTheme.bodyLarge)!.copyWith(
      color: backgroundColor != null
          ? backgroundColor!.computeLuminance() > .5
              ? Colors.black
              : Colors.white
          : Theme.of(context).colorScheme.onSurface,
      fontWeight: values.isFirstDayOfWeek || values.isLastDayOfWeek
          ? FontWeight.bold
          : null,
    );

    if (values.isSelected) {
      if (values.isFirstDayOfWeek) {
        borderRadius = BorderRadius.only(
          topLeft: Radius.circular(radius),
          bottomLeft: Radius.circular(radius),
        );
      } else if (values.isLastDayOfWeek) {
        borderRadius = BorderRadius.only(
          topRight: Radius.circular(radius),
          bottomRight: Radius.circular(radius),
        );
      }

      if ((values.selectedMinDate != null &&
              values.day.isSameDay(values.selectedMinDate!)) ||
          (values.selectedMaxDate != null &&
              values.day.isSameDay(values.selectedMaxDate!))) {
        bgColor =
            selectedBackgroundColor ?? Theme.of(context).colorScheme.primary;
        txtStyle =
            (textStyle ?? Theme.of(context).textTheme.bodyLarge)!.copyWith(
          color: selectedBackgroundColor != null
              ? selectedBackgroundColor!.computeLuminance() > .5
                  ? Colors.black
                  : Colors.white
              : Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        );

        if (values.selectedMinDate == values.selectedMaxDate) {
          borderRadius = BorderRadius.circular(radius);
        } else if (values.selectedMinDate != null &&
            values.day.isSameDay(values.selectedMinDate!)) {
          borderRadius = BorderRadius.only(
            topLeft: Radius.circular(radius),
            bottomLeft: Radius.circular(radius),
          );
        } else if (values.selectedMaxDate != null &&
            values.day.isSameDay(values.selectedMaxDate!)) {
          borderRadius = BorderRadius.only(
            topRight: Radius.circular(radius),
            bottomRight: Radius.circular(radius),
          );
        }
      } else {
        bgColor = selectedBackgroundColorBetween ??
            Theme.of(context).colorScheme.primary.withOpacity(.3);
        txtStyle =
            (textStyle ?? Theme.of(context).textTheme.bodyLarge)!.copyWith(
          color:
              selectedBackgroundColor ?? Theme.of(context).colorScheme.primary,
          fontWeight: values.isFirstDayOfWeek || values.isLastDayOfWeek
              ? FontWeight.bold
              : null,
        );
      }
    } else if (values.day.isSameDay(values.minDate)) {
    } else if (values.day.isBefore(values.minDate) ||
        values.day.isAfter(values.maxDate)) {
      txtStyle = (textStyle ?? Theme.of(context).textTheme.bodyLarge)!.copyWith(
        color: dayDisableColor ??
            Theme.of(context).colorScheme.onSurface.withOpacity(.5),
        decoration: TextDecoration.lineThrough,
        fontWeight: values.isFirstDayOfWeek || values.isLastDayOfWeek
            ? FontWeight.bold
            : null,
      );
    }

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: borderRadius,
      ),
      child: Text(
        values.text,
        textAlign: TextAlign.center,
        style: txtStyle,
      ),
    );
  }
}

class _WeeksNumberCount extends StatelessWidget {
  final double weekNumber;
  const _WeeksNumberCount({required this.weekNumber});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 48.7,
      child: Align(
        alignment: Alignment.center,
        child: Text(
          'S${weekNumber.toInt()}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
