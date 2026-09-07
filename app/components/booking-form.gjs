import Component from '@glimmer/component';

import { tracked } from '@glimmer/tracking';

import { service } from '@ember/service';

const MONTH_NAMES = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const DAY_NAMES = [
  'Sun',
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
];

export default class BookingFormComponent extends Component {
  @service store;

  @tracked submitted = false;

  @tracked confirmationNumber = '';

  @tracked customerName = '';

  @tracked errorMessage = '';

  @tracked submitting = false;

  @tracked selectedService = '';

  @tracked selectedDate = '';

  @tracked selectedTime = '';

  @tracked availableTimes = [];

  @tracked checkingAvailability = false;

  @tracked availabilityMessage = '';

  @tracked calendarMonth;

  @tracked calendarYear;

  @tracked availabilityBlocks = [];

  @tracked loadingCalendarBlocks = false;

  constructor(owner, args) {
    super(owner, args);

    const today = new Date();

    this.calendarMonth = today.getMonth();

    this.calendarYear = today.getFullYear();

    this.loadCalendarBlocks();
  }

  get monthName() {
    return MONTH_NAMES[this.calendarMonth];
  }

  get dayNames() {
    return DAY_NAMES;
  }

  get canGoPreviousMonth() {
    const today = new Date();

    if (
      this.calendarYear >
      today.getFullYear()
    ) {
      return true;
    }

    if (
      this.calendarYear <
      today.getFullYear()
    ) {
      return false;
    }

    return (
      this.calendarMonth >
      today.getMonth()
    );
  }

  get previousMonthClass() {
    return this.canGoPreviousMonth
      ? 'calendar-nav'
      : 'calendar-nav disabled';
  }

  get timeOptions() {
    return this.availableTimes.map(
      (time) => {
        const selected =
          time === this.selectedTime;

        return {
          value: time,
          selected,
          className: selected
            ? 'time-button selected'
            : 'time-button',
        };
      },
    );
  }

  get fullDayBlockedDates() {
    return new Set(
      this.availabilityBlocks
        .filter(
          (block) =>
            block.block_type === 'day',
        )
        .map(
          (block) =>
            block.block_date,
        ),
    );
  }

  get partiallyBlockedDates() {
    return new Set(
      this.availabilityBlocks
        .filter(
          (block) =>
            block.block_type === 'time',
        )
        .map(
          (block) =>
            block.block_date,
        ),
    );
  }

  get calendarDays() {
    const firstDay = new Date(
      this.calendarYear,
      this.calendarMonth,
      1,
    ).getDay();

    const daysInMonth = new Date(
      this.calendarYear,
      this.calendarMonth + 1,
      0,
    ).getDate();

    const previousMonthDays =
      new Date(
        this.calendarYear,
        this.calendarMonth,
        0,
      ).getDate();

    const days = [];

    for (
      let i = firstDay - 1;
      i >= 0;
      i -= 1
    ) {
      const date = new Date(
        this.calendarYear,
        this.calendarMonth - 1,
        previousMonthDays - i,
      );

      days.push(
        this.createCalendarDay(
          date,
          true,
        ),
      );
    }

    for (
      let day = 1;
      day <= daysInMonth;
      day += 1
    ) {
      const date = new Date(
        this.calendarYear,
        this.calendarMonth,
        day,
      );

      days.push(
        this.createCalendarDay(
          date,
          false,
        ),
      );
    }

    let nextDay = 1;

    while (days.length < 42) {
      const date = new Date(
        this.calendarYear,
        this.calendarMonth + 1,
        nextDay,
      );

      days.push(
        this.createCalendarDay(
          date,
          true,
        ),
      );

      nextDay += 1;
    }

    return days;
  }

  createCalendarDay(
    date,
    outsideMonth,
  ) {
    const dateString =
      this.formatDateForDatabase(
        date,
      );

    const today = new Date();

    const todayString =
      this.formatDateForDatabase(
        today,
      );

    const isToday =
      dateString === todayString;

    const isPast =
      dateString < todayString;

    const isSelected =
      dateString ===
      this.selectedDate;

    const isSunday =
      date.getDay() === 0;

    const isFullyBlocked =
      this.fullDayBlockedDates.has(
        dateString,
      );

    const isPartiallyBlocked =
      this.partiallyBlockedDates.has(
        dateString,
      );

    const disabled =
      outsideMonth ||
      isPast ||
      isSunday ||
      isFullyBlocked;

    return {
      day: date.getDate(),
      date: dateString,
      outsideMonth,
      isToday,
      isPast,
      isSelected,
      isSunday,
      isFullyBlocked,
      isPartiallyBlocked,
      disabled,
      className:
        this.getCalendarDayClass({
          outsideMonth,
          isToday,
          isSelected,
          isPast,
          isSunday,
          isFullyBlocked,
          isPartiallyBlocked,
        }),
      title:
        this.getCalendarDayTitle({
          isSunday,
          isFullyBlocked,
          isPartiallyBlocked,
        }),
    };
  }

  getCalendarDayClass({
    outsideMonth,
    isToday,
    isSelected,
    isPast,
    isSunday,
    isFullyBlocked,
    isPartiallyBlocked,
  }) {
    let className =
      'calendar-day';

    if (outsideMonth) {
      className += ' outside';
    }

    if (isToday) {
      className += ' today';
    }

    if (isSelected) {
      className += ' selected';
    }

    if (isPast) {
      className += ' past';
    }

    if (isSunday) {
      className += ' sunday';
    }

    if (isFullyBlocked) {
      className +=
        ' fully-blocked';
    }

    if (
      isPartiallyBlocked &&
      !isFullyBlocked
    ) {
      className +=
        ' partially-blocked';
    }

    return className;
  }

  getCalendarDayTitle({
    isSunday,
    isFullyBlocked,
    isPartiallyBlocked,
  }) {
    if (isSunday) {
      return 'Closed Sunday';
    }

    if (isFullyBlocked) {
      return 'Unavailable';
    }

    if (isPartiallyBlocked) {
      return 'Limited availability';
    }

    return 'Available';
  }

  async loadCalendarBlocks() {
    this.loadingCalendarBlocks =
      true;

    try {
      const blocks =
        await this.store
          .getAvailabilityBlocks();

      this.availabilityBlocks =
        blocks || [];
    } catch (error) {
      console.error(
        'Could not load calendar availability blocks:',
        error,
      );

      this.availabilityBlocks =
        [];
    } finally {
      this.loadingCalendarBlocks =
        false;
    }
  }

  formatDateForDatabase(date) {
    const year =
      date.getFullYear();

    const month =
      String(
        date.getMonth() + 1,
      ).padStart(
        2,
        '0',
      );

    const day =
      String(
        date.getDate(),
      ).padStart(
        2,
        '0',
      );

    return `${year}-${month}-${day}`;
  }

  serviceChanged = async (
    event,
  ) => {
    this.selectedService =
      event.target.value;

    this.selectedTime = '';

    this.availableTimes = [];

    this.availabilityMessage =
      '';

    this.errorMessage = '';

    if (!this.selectedService) {
      return;
    }

    if (this.selectedDate) {
      await this.refreshAvailability(
        this.selectedDate,
      );
    }
  };

  previousMonth = async () => {
    if (!this.canGoPreviousMonth) {
      return;
    }

    if (
      this.calendarMonth === 0
    ) {
      this.calendarMonth = 11;

      this.calendarYear -= 1;
    } else {
      this.calendarMonth -= 1;
    }

    this.clearSelectedTime();

    await this.loadCalendarBlocks();
  };

  nextMonth = async () => {
    if (
      this.calendarMonth === 11
    ) {
      this.calendarMonth = 0;

      this.calendarYear += 1;
    } else {
      this.calendarMonth += 1;
    }

    this.clearSelectedTime();

    await this.loadCalendarBlocks();
  };

  goToToday = async () => {
    const today = new Date();

    this.calendarMonth =
      today.getMonth();

    this.calendarYear =
      today.getFullYear();

    await this.loadCalendarBlocks();

    const todayString =
      this.formatDateForDatabase(
        today,
      );

    if (
      today.getDay() === 0
    ) {
      this.selectedDate = '';

      this.selectedTime = '';

      this.availableTimes = [];

      this.availabilityMessage =
        'We are closed on Sundays. Please choose another date.';

      return;
    }

    if (
      this.fullDayBlockedDates.has(
        todayString,
      )
    ) {
      this.selectedDate = '';

      this.selectedTime = '';

      this.availableTimes = [];

      this.availabilityMessage =
        'Today is unavailable. Please choose another date.';

      return;
    }

    if (this.selectedService) {
      await this.selectDate(
        todayString,
      );
    } else {
      this.selectedDate = '';

      this.selectedTime = '';

      this.availableTimes = [];

      this.availabilityMessage =
        '';

      this.errorMessage =
        'Please choose a service first.';
    }
  };

  selectDate = async (
    date,
  ) => {
    if (!date) {
      return;
    }

    if (!this.selectedService) {
      this.errorMessage =
        'Please choose a service first.';

      return;
    }

    const today = new Date();

    const todayString =
      this.formatDateForDatabase(
        today,
      );

    if (date < todayString) {
      return;
    }

    const parts =
      date.split('-');

    const selectedDateObject =
      new Date(
        Number(parts[0]),
        Number(parts[1]) - 1,
        Number(parts[2]),
      );

    if (
      selectedDateObject.getDay() ===
      0
    ) {
      this.availabilityMessage =
        'We are closed on Sundays. Please choose another date.';

      return;
    }

    if (
      this.fullDayBlockedDates.has(
        date,
      )
    ) {
      this.availabilityMessage =
        'This date is unavailable. Please choose another date.';

      return;
    }

    this.selectedDate = date;

    this.selectedTime = '';

    this.availableTimes = [];

    this.errorMessage = '';

    this.availabilityMessage =
      'Checking available times...';

    this.checkingAvailability =
      true;

    try {
      this.availableTimes =
        await this.store
          .getAvailableTimes(
            date,
            this.selectedService,
          );

      if (
        this.availableTimes.length ===
        0
      ) {
        this.availabilityMessage =
          'No appointment times are available on this date. Please choose another date.';
      } else {
        const count =
          this.availableTimes.length;

        this.availabilityMessage =
          `${count} time${count === 1 ? '' : 's'} available`;
      }
    } catch (error) {
      console.error(
        'Availability error:',
        error,
      );

      this.availableTimes = [];

      this.availabilityMessage =
        'We could not check availability. Please try again.';
    } finally {
      this.checkingAvailability =
        false;
    }
  };

  selectTime = (time) => {
    this.selectedTime = time;

    this.errorMessage = '';
  };

  handleCalendarDayClick =
    async (event) => {
      const date =
        event.currentTarget
          .dataset.date;

      await this.selectDate(
        date,
      );
    };

  handleTimeClick = (
    event,
  ) => {
    const time =
      event.currentTarget
        .dataset.time;

    this.selectTime(time);
  };

  clearSelectedTime = () => {
    this.selectedDate = '';

    this.selectedTime = '';

    this.availableTimes = [];

    this.availabilityMessage =
      '';

    this.errorMessage = '';
  };

  get formattedSelectedDate() {
    if (!this.selectedDate) {
      return '';
    }

    const parts =
      this.selectedDate.split(
        '-',
      );

    const date =
      new Date(
        Number(parts[0]),
        Number(parts[1]) - 1,
        Number(parts[2]),
      );

    return date.toLocaleDateString(
      'en-US',
      {
        weekday: 'long',
        month: 'long',
        day: 'numeric',
        year: 'numeric',
      },
    );
  }

  async refreshAvailability(
    date,
  ) {
    if (
      !date ||
      !this.selectedService
    ) {
      return;
    }

    await this.loadCalendarBlocks();

    if (
      this.fullDayBlockedDates.has(
        date,
      )
    ) {
      this.selectedDate = '';

      this.selectedTime = '';

      this.availableTimes = [];

      this.availabilityMessage =
        'This date is unavailable. Please choose another date.';

      return;
    }

    this.checkingAvailability =
      true;

    this.selectedTime = '';

    try {
      this.availableTimes =
        await this.store
          .getAvailableTimes(
            date,
            this.selectedService,
          );

      if (
        this.availableTimes.length ===
        0
      ) {
        this.availabilityMessage =
          'No appointment times are available on this date.';
      } else {
        const count =
          this.availableTimes.length;

        this.availabilityMessage =
          `${count} time${count === 1 ? '' : 's'} available`;
      }
    } catch (error) {
      console.error(
        'Could not refresh availability:',
        error,
      );

      this.availableTimes = [];

      this.availabilityMessage =
        'We could not check availability. Please try again.';
    } finally {
      this.checkingAvailability =
        false;
    }
  }

  submitAppointment = async (
    event,
  ) => {
    event.preventDefault();

    if (this.submitting) {
      return;
    }

    const form =
      event.currentTarget;

    if (!this.selectedService) {
      this.errorMessage =
        'Please choose a service.';

      return;
    }

    if (!this.selectedDate) {
      this.errorMessage =
        'Please choose an appointment date.';

      return;
    }

    if (!this.selectedTime) {
      this.errorMessage =
        'Please choose an available appointment time.';

      return;
    }

    if (!form.checkValidity()) {
      form.reportValidity();

      return;
    }

    const formData =
      new FormData(form);

    const appointment = {
      firstName:
        formData.get(
          'firstName',
        ),
      lastName:
        formData.get(
          'lastName',
        ),
      email:
        formData.get(
          'email',
        ),
      phone:
        formData.get(
          'phone',
        ),
      service:
        this.selectedService,
      date:
        this.selectedDate,
      time:
        this.selectedTime,
      message:
        formData.get(
          'message',
        ) || '',
    };

    this.submitting = true;

    this.errorMessage = '';

    try {
      const available =
        await this.store
          .isTimeAvailable(
            appointment.date,
            appointment.time,
            appointment.service,
          );

      if (!available) {
        this.errorMessage =
          'That appointment time is no longer available. Please choose another time.';

        await this.refreshAvailability(
          appointment.date,
        );

        return;
      }

      let savedAppointment;

      try {
        savedAppointment =
          await this.store
            .saveAppointment(
              appointment,
            );
      } catch (error) {
        if (
          error?.message ===
          'TIME_ALREADY_BOOKED'
        ) {
          this.errorMessage =
            'That appointment time was just booked by someone else. Please choose another time.';

          await this.refreshAvailability(
            appointment.date,
          );

          return;
        }

        throw error;
      }

      try {
        await this.store
          .sendBookingEmail({
            ...appointment,
            confirmationNumber:
              savedAppointment
                .confirmation_number ||
              savedAppointment.id,
          });
      } catch (emailError) {
        console.error(
          'Booking email error:',
          emailError,
        );

        this.confirmationNumber =
          savedAppointment
            .confirmation_number ||
          savedAppointment.id;

        this.customerName =
          `${appointment.firstName} ${appointment.lastName}`.trim();

        this.errorMessage =
          'Your appointment was saved successfully, but the email notification could not be sent. Mariia can still see your appointment in the booking system.';

        this.submitted = true;

        form.reset();

        return;
      }

      this.confirmationNumber =
        savedAppointment
          .confirmation_number ||
        savedAppointment.id;

      this.customerName =
        `${appointment.firstName} ${appointment.lastName}`.trim();

      this.errorMessage = '';

      this.submitted = true;

      form.reset();
    } catch (error) {
      console.error(
        'Appointment submission error:',
        error,
      );

      this.errorMessage =
        'We could not submit your appointment. Please try again.';
    } finally {
      this.submitting = false;
    }
  };

  startNewAppointment =
    async () => {
      this.submitted = false;

      this.confirmationNumber =
        '';

      this.customerName = '';

      this.errorMessage = '';

      this.submitting = false;

      const today =
        new Date();

      this.calendarMonth =
        today.getMonth();

      this.calendarYear =
        today.getFullYear();

      this.selectedService = '';

      this.selectedDate = '';

      this.selectedTime = '';

      this.availableTimes = [];

      this.availabilityMessage =
        '';

      await this.loadCalendarBlocks();
    };

  <template>
    <style>
      .pretty-booking {
        width: 100%;
        min-width: 0;
        overflow: hidden;
      }

      .pretty-booking,
      .pretty-booking * {
        box-sizing: border-box;
      }

      .pretty-booking form {
        width: 100%;
        min-width: 0;
      }

      .booking-step {
        width: 100%;
        min-width: 0;
        margin-bottom: 32px;
      }

      .booking-step-header {
        display: flex;
        align-items: center;
        gap: 12px;
        margin-bottom: 16px;
      }

      .booking-step-number {
        width: 32px;
        height: 32px;
        flex: 0 0 32px;
        border-radius: 50%;
        background: #241b18;
        color: #fff;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        font-size: 12px;
        font-weight: 600;
      }

      .booking-step-header h3 {
        min-width: 0;
        margin: 0;
        font-family:
          'Cormorant Garamond',
          serif;
        font-size: 27px;
        font-weight: 500;
        line-height: 1.1;
      }

      .pretty-booking .form-group {
        width: 100%;
        min-width: 0;
      }

      .pretty-booking label {
        display: flex;
        align-items: center;
        gap: 6px;
      }

      .field-required {
        color: #a66d62;
        font-size: 12px;
      }

      .field-optional {
        color: #a08d85;
        font-size: 10px;
        font-weight: 400;
        letter-spacing: 0.04em;
        text-transform: uppercase;
      }

      .pretty-booking select,
      .pretty-booking input,
      .pretty-booking textarea {
        width: 100%;
        max-width: 100%;
        min-width: 0;
        box-sizing: border-box;
      }

      .booking-calendar {
        width: 100%;
        min-width: 0;
        overflow: hidden;
        border: 1px solid #e7ddd7;
        border-radius: 18px;
        padding: 20px;
        background: #fff;
      }

      .calendar-header {
        display: grid;
        grid-template-columns:
          44px
          minmax(0, 1fr)
          44px;
        align-items: center;
        gap: 10px;
        margin-bottom: 18px;
      }

      .calendar-month {
        min-width: 0;
        text-align: center;
      }

      .calendar-month strong {
        display: block;
        font-family:
          'Cormorant Garamond',
          serif;
        font-size: 27px;
        font-weight: 500;
        line-height: 1.1;
        color: #241b18;
      }

      .calendar-month span {
        display: block;
        margin-top: 4px;
        font-size: 10px;
        letter-spacing: 0.12em;
        text-transform: uppercase;
        color: #9a8880;
      }

      .calendar-nav {
        width: 42px;
        height: 42px;
        padding: 0;
        display: flex;
        align-items: center;
        justify-content: center;
        border: 1px solid #e7ddd7;
        background: #fff;
        border-radius: 50%;
        cursor: pointer;
        font-size: 22px;
        color: #5f4b43;
        transition:
          background 0.2s ease,
          border-color 0.2s ease,
          opacity 0.2s ease;
      }

      .calendar-nav:hover:not(:disabled) {
        background: #f8f1ed;
        border-color: #cbb6aa;
      }

      .calendar-nav.disabled,
      .calendar-nav:disabled {
        opacity: 0.3;
        cursor: not-allowed;
      }

      .calendar-today {
        min-height: 38px;
        margin: 0 auto 15px;
        padding: 0 15px;
        display: block;
        border: 0;
        background: transparent;
        color: #8d6f60;
        font-size: 10px;
        font-weight: 600;
        letter-spacing: 0.1em;
        text-transform: uppercase;
        cursor: pointer;
      }

      .calendar-weekdays,
      .calendar-grid {
        width: 100%;
        display: grid;
        grid-template-columns:
          repeat(
            7,
            minmax(0, 1fr)
          );
        gap: 6px;
      }

      .calendar-weekdays {
        margin-bottom: 7px;
      }

      .calendar-weekday {
        text-align: center;
        font-size: 9px;
        font-weight: 600;
        color: #a28f87;
        text-transform: uppercase;
      }

      .calendar-day {
        position: relative;
        width: 100%;
        min-width: 0;
        min-height: 44px;
        aspect-ratio: 1 / 1;
        padding: 0;
        display: flex;
        align-items: center;
        justify-content: center;
        border: 1px solid transparent;
        border-radius: 12px;
        background: #faf7f5;
        color: #443530;
        cursor: pointer;
        font-size: 13px;
        transition: all 0.2s ease;
      }

      .calendar-day:hover:not(:disabled) {
        border-color: #cbb6aa;
        background: #f4ebe6;
      }

      .calendar-day.today {
        border-color: #b79786;
        font-weight: 700;
      }

      .calendar-day.selected {
        background: #241b18;
        color: #fff;
        border-color: #241b18;
        box-shadow:
          0 5px 14px
          rgba(36, 27, 24, 0.16);
      }

      .calendar-day.outside {
        background: transparent;
        color: #d4c9c4;
      }

      .calendar-day.past {
        background: #f8f5f3;
        color: #d0c5c0;
      }

      .calendar-day.sunday {
        background: #f5f1ef;
        color: #d0c4bf;
        text-decoration: line-through;
        opacity: 0.7;
      }

      .calendar-day.fully-blocked {
        background: #ead8d8;
        border-color: #d7b4b4;
        color: #9d5555;
        font-weight: 600;
        cursor: not-allowed;
        text-decoration: line-through;
        opacity: 1;
      }

      .calendar-day.fully-blocked::after {
        content: '';
        position: absolute;
        bottom: 5px;
        left: 50%;
        width: 5px;
        height: 5px;
        transform: translateX(-50%);
        border-radius: 50%;
        background: #a75858;
      }

      .calendar-day.partially-blocked::after {
        content: '';
        position: absolute;
        bottom: 5px;
        left: 50%;
        width: 5px;
        height: 5px;
        transform: translateX(-50%);
        border-radius: 50%;
        background: #b48a74;
      }

      .calendar-day.partially-blocked {
        border-color: #e0cabc;
      }

      .calendar-day.selected.partially-blocked::after {
        background: #fff;
      }

      .calendar-legend {
        margin-top: 15px;
        padding-top: 14px;
        display: flex;
        flex-wrap: wrap;
        justify-content: center;
        gap: 15px;
        border-top:
          1px solid #eee5e0;
      }

      .calendar-legend-item {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        color: #8b7970;
        font-size: 10px;
      }

      .calendar-legend-dot {
        width: 7px;
        height: 7px;
        border-radius: 50%;
        background: #b48a74;
      }

      .calendar-legend-blocked {
        width: 10px;
        height: 10px;
        border-radius: 3px;
        background: #ead8d8;
        border: 1px solid #d7b4b4;
      }

      .selected-date-card {
        width: 100%;
        margin-top: 15px;
        padding: 14px 15px;
        border-radius: 12px;
        background: #f8f1ed;
        text-align: center;
        color: #5e4940;
        font-size: 12px;
      }

      .selected-date-card strong {
        display: block;
        margin-top: 4px;
        font-family:
          'Cormorant Garamond',
          serif;
        font-size: 20px;
        font-weight: 500;
        color: #241b18;
      }

      .time-heading {
        margin-bottom: 13px;
      }

      .time-heading span {
        display: block;
        font-size: 10px;
        color: #a08d85;
        letter-spacing: 0.06em;
        text-transform: uppercase;
      }

      .time-grid {
        width: 100%;
        display: grid;
        grid-template-columns:
          repeat(
            3,
            minmax(0, 1fr)
          );
        gap: 9px;
      }

      .time-button {
        position: relative;
        width: 100%;
        min-height: 50px;
        padding: 8px 6px;
        border: 1px solid #dfd3cc;
        border-radius: 11px;
        background: #fff;
        color: #4b3932;
        font-size: 13px;
        font-weight: 500;
        cursor: pointer;
        transition: all 0.2s ease;
      }

      .time-button:hover {
        border-color: #b79786;
        background: #faf4f1;
      }

      .time-button.selected,
      .time-button.selected:hover {
        background: #241b18;
        border-color: #241b18;
        color: #fff;
        box-shadow:
          0 5px 14px
          rgba(36, 27, 24, 0.16);
      }

      .time-button.selected::after {
        content: '✓';
        margin-left: 6px;
        font-size: 11px;
      }

      .time-empty {
        width: 100%;
        padding: 18px;
        border-radius: 12px;
        background: #faf7f5;
        text-align: center;
        color: #8e7b73;
        font-size: 13px;
        line-height: 1.6;
      }

      .pretty-booking .form-row {
        width: 100%;
        display: grid;
        grid-template-columns:
          repeat(
            2,
            minmax(0, 1fr)
          );
        gap: 16px;
      }

      .appointment-summary {
        width: 100%;
        margin:
          8px
          0
          22px;
        padding: 18px;
        border: 1px solid #e5d8d1;
        border-radius: 14px;
        background: #fbf7f4;
      }

      .appointment-summary-label {
        display: block;
        margin-bottom: 7px;
        color: #9a8880;
        font-size: 10px;
        font-weight: 600;
        letter-spacing: 0.1em;
        text-transform: uppercase;
      }

      .appointment-summary-service {
        display: block;
        margin-bottom: 5px;
        color: #241b18;
        font-family:
          'Cormorant Garamond',
          serif;
        font-size: 21px;
        font-weight: 500;
        line-height: 1.2;
      }

      .appointment-summary-time {
        color: #765f55;
        font-size: 13px;
        line-height: 1.5;
      }

      .booking-error {
        margin-bottom: 18px;
      }

      .submit-button {
        width: 100%;
      }

      .submit-button:disabled {
        opacity: 0.65;
        cursor: wait;
      }

      .form-note {
        max-width: 520px;
        margin:
          13px
          auto
          0;
        text-align: center;
        line-height: 1.5;
      }

      .booking-success {
        text-align: center;
      }

      .confirmation-box {
        word-break: break-word;
      }

      @media (max-width: 600px) {
        .booking-step {
          margin-bottom: 26px;
        }

        .booking-step-header h3 {
          font-size: 23px;
        }

        .booking-calendar {
          padding:
            13px
            10px
            14px;
          border-radius: 14px;
        }

        .calendar-header {
          grid-template-columns:
            38px
            minmax(0, 1fr)
            38px;
          gap: 5px;
        }

        .calendar-nav {
          width: 36px;
          height: 36px;
        }

        .calendar-month strong {
          font-size: 22px;
        }

        .calendar-weekdays,
        .calendar-grid {
          gap: 4px;
        }

        .calendar-day {
          min-height: 38px;
          border-radius: 9px;
          font-size: 12px;
        }

        .time-grid {
          grid-template-columns:
            repeat(
              2,
              minmax(0, 1fr)
            );
        }

        .pretty-booking .form-row {
          grid-template-columns: 1fr;
          gap: 0;
        }

        .appointment-summary {
          padding: 15px;
        }
      }

      @media (max-width: 430px) {
        .booking-calendar {
          padding:
            11px
            7px
            12px;
        }

        .calendar-weekdays,
        .calendar-grid {
          gap: 3px;
        }

        .calendar-day {
          min-height: 35px;
          font-size: 11px;
        }

        .calendar-legend {
          gap: 10px;
        }

        .appointment-summary-service {
          font-size: 19px;
        }
      }
    </style>

    <div class="booking-form pretty-booking">
      {{#if this.submitted}}
        <div
          class="booking-success"
          role="status"
          aria-live="polite"
        >
          <div class="success-icon">
            ✓
          </div>

          <p class="eyebrow">
            APPOINTMENT REQUEST RECEIVED
          </p>

          <h3>
            Thank you,
            {{this.customerName}}!
          </h3>

          <p>
            Your appointment request has
            been received successfully.
            We sent you an email with your
            request details. Mariia will
            review the appointment and send
            you another email once it is
            confirmed.
          </p>

          <div class="confirmation-box">
            <span>
              Confirmation Number
            </span>

            <strong>
              {{this.confirmationNumber}}
            </strong>
          </div>

          {{#if this.errorMessage}}
            <div
              class="booking-error"
              role="alert"
            >
              {{this.errorMessage}}
            </div>
          {{/if}}

          <button
            type="button"
            class="button button-primary"
            onclick={{this.startNewAppointment}}
          >
            Request Another Appointment
          </button>
        </div>
      {{else}}
        <form
          onsubmit={{this.submitAppointment}}
        >
          <div class="booking-step">
            <div class="booking-step-header">
              <span class="booking-step-number">
                1
              </span>

              <h3>
                Choose your service
              </h3>
            </div>

            <div class="form-group">
              <select
                id="booking-service"
                name="service"
                required
                onchange={{this.serviceChanged}}
              >
                <option value="">
                  Select a service
                </option>

                {{#each @services as |service|}}
                  <option
                    value={{service.name}}
                  >
                    {{service.name}}
                    —
                    {{service.price}}
                    ·
                    {{service.time}}
                  </option>
                {{/each}}
              </select>
            </div>
          </div>

          <div class="booking-step">
            <div class="booking-step-header">
              <span class="booking-step-number">
                2
              </span>

              <h3>
                Choose your date
              </h3>
            </div>

            <div class="booking-calendar">
              <div class="calendar-header">
                <button
                  type="button"
                  class={{this.previousMonthClass}}
                  aria-label="Previous month"
                  disabled={{if this.canGoPreviousMonth false true}}
                  onclick={{this.previousMonth}}
                >
                  ‹
                </button>

                <div class="calendar-month">
                  <strong>
                    {{this.monthName}}
                    {{this.calendarYear}}
                  </strong>

                  <span>
                    Select a date
                  </span>
                </div>

                <button
                  type="button"
                  class="calendar-nav"
                  aria-label="Next month"
                  onclick={{this.nextMonth}}
                >
                  ›
                </button>
              </div>

              <button
                type="button"
                class="calendar-today"
                onclick={{this.goToToday}}
              >
                Today
              </button>

              <div class="calendar-weekdays">
                {{#each this.dayNames as |dayName|}}
                  <div class="calendar-weekday">
                    {{dayName}}
                  </div>
                {{/each}}
              </div>

              <div class="calendar-grid">
                {{#each this.calendarDays as |day|}}
                  <button
                    type="button"
                    class={{day.className}}
                    disabled={{day.disabled}}
                    data-date={{day.date}}
                    title={{day.title}}
                    aria-label={{day.title}}
                    aria-pressed={{day.isSelected}}
                    onclick={{this.handleCalendarDayClick}}
                  >
                    {{day.day}}
                  </button>
                {{/each}}
              </div>

              <div class="calendar-legend">
                <span class="calendar-legend-item">
                  <span class="calendar-legend-dot"></span>
                  Limited availability
                </span>

                <span class="calendar-legend-item">
                  <span class="calendar-legend-blocked"></span>
                  Unavailable
                </span>
              </div>

              {{#if this.selectedDate}}
                <div class="selected-date-card">
                  Selected date

                  <strong>
                    {{this.formattedSelectedDate}}
                  </strong>
                </div>
              {{/if}}
            </div>
          </div>

          <div class="booking-step">
            <div class="booking-step-header">
              <span class="booking-step-number">
                3
              </span>

              <h3>
                Choose your time
              </h3>
            </div>

            {{#if this.selectedDate}}
              <div
                class="time-heading"
                aria-live="polite"
              >
                <span>
                  {{this.availabilityMessage}}
                </span>
              </div>

              {{#if this.checkingAvailability}}
                <div
                  class="time-empty"
                  role="status"
                >
                  Finding available
                  appointment times...
                </div>
              {{else}}
                {{#if this.availableTimes.length}}
                  <div class="time-grid">
                    {{#each this.timeOptions as |timeOption|}}
                      <button
                        type="button"
                        class={{timeOption.className}}
                        data-time={{timeOption.value}}
                        aria-pressed={{timeOption.selected}}
                        onclick={{this.handleTimeClick}}
                      >
                        {{timeOption.value}}
                      </button>
                    {{/each}}
                  </div>
                {{else}}
                  <div class="time-empty">
                    No appointment times
                    are available on this
                    date. Please choose
                    another date.
                  </div>
                {{/if}}
              {{/if}}
            {{else}}
              <div class="time-empty">
                {{#if this.selectedService}}
                  Select a date above to
                  see available times.
                {{else}}
                  Choose a service first
                  to see available times.
                {{/if}}
              </div>
            {{/if}}
          </div>

          <div class="booking-step">
            <div class="booking-step-header">
              <span class="booking-step-number">
                4
              </span>

              <h3>
                Your information
              </h3>
            </div>

            <div class="form-row">
              <div class="form-group">
                <label for="booking-first-name">
                  First Name
                  <span class="field-required">
                    *
                  </span>
                </label>

                <input
                  id="booking-first-name"
                  name="firstName"
                  type="text"
                  placeholder="First name"
                  autocomplete="given-name"
                  required
                />
              </div>

              <div class="form-group">
                <label for="booking-last-name">
                  Last Name
                  <span class="field-required">
                    *
                  </span>
                </label>

                <input
                  id="booking-last-name"
                  name="lastName"
                  type="text"
                  placeholder="Last name"
                  autocomplete="family-name"
                  required
                />
              </div>
            </div>

            <div class="form-group">
              <label for="booking-email">
                Email
                <span class="field-required">
                  *
                </span>
              </label>

              <input
                id="booking-email"
                name="email"
                type="email"
                placeholder="you@example.com"
                autocomplete="email"
                required
              />
            </div>

            <div class="form-group">
              <label for="booking-phone">
                Phone
                <span class="field-required">
                  *
                </span>
              </label>

              <input
                id="booking-phone"
                name="phone"
                type="tel"
                placeholder="(555) 555-5555"
                autocomplete="tel"
                required
              />
            </div>

            <div class="form-group">
              <label for="booking-message">
                Message

                <span class="field-optional">
                  Optional
                </span>
              </label>

              <textarea
                id="booking-message"
                name="message"
                rows="4"
                placeholder="Tell me anything you'd like me to know..."
              ></textarea>
            </div>
          </div>

          {{#if this.selectedTime}}
            <div class="appointment-summary">
              <span class="appointment-summary-label">
                Your appointment request
              </span>

              <strong class="appointment-summary-service">
                {{this.selectedService}}
              </strong>

              <div class="appointment-summary-time">
                {{this.formattedSelectedDate}}
                ·
                {{this.selectedTime}}
              </div>
            </div>
          {{/if}}

          {{#if this.errorMessage}}
            <div
              class="booking-error"
              role="alert"
              aria-live="assertive"
            >
              {{this.errorMessage}}
            </div>
          {{/if}}

          <button
            type="submit"
            class="button button-primary submit-button"
            disabled={{this.submitting}}
          >
            {{#if this.submitting}}
              Sending Request...
            {{else}}
              Request Appointment
            {{/if}}
          </button>

          <p class="form-note">
            Your appointment is not confirmed
            until Mariia approves it and you
            receive a confirmation email.
          </p>
        </form>
      {{/if}}
    </div>
  </template>
}
