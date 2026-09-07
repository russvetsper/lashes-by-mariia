import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { service } from '@ember/service';

const ADMIN_EMAIL = 'lashesmariia@gmail.com';

const BLOCK_TIME_OPTIONS = [
  '9:00 AM',
  '9:45 AM',
  '10:30 AM',
  '11:15 AM',
  '12:00 PM',
  '12:45 PM',
  '1:30 PM',
  '2:15 PM',
  '3:00 PM',
  '3:45 PM',
  '4:30 PM',
  '5:15 PM',
  '6:00 PM',
];

function formatShortDate(date) {
  if (!date) {
    return '';
  }

  return new Date(
    `${date}T00:00:00`,
  ).toLocaleDateString(
    'en-US',
    {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    },
  );
}

function formatLongDate(date) {
  if (!date) {
    return '';
  }

  return new Date(
    `${date}T00:00:00`,
  ).toLocaleDateString(
    'en-US',
    {
      weekday: 'long',
      month: 'long',
      day: 'numeric',
      year: 'numeric',
    },
  );
}

function getServiceDuration(serviceName) {
  const durations = {
    'Lash Lift & Lash Lamination':
      '45 min',

    'Classic Full Set':
      '2 hr 15 min',

    'Hybrid Full Set':
      '2 hr 30 min',

    'Volume Full Set':
      '2 hr 45 min',

    'Lash Fill':
      '1 hr 30 min',
  };

  return (
    durations[serviceName] ||
    ''
  );
}

function getStatusLabel(status) {
  if (status === 'pending') {
    return 'Pending';
  }

  if (status === 'confirmed') {
    return 'Confirmed';
  }

  if (status === 'cancelled') {
    return 'Cancelled';
  }

  return status || '';
}

function getCustomerName(appointment) {
  const name =
    `${appointment.first_name || ''} ${appointment.last_name || ''}`.trim();

  return name || 'Customer';
}

export default class AdminDashboardComponent extends Component {
  @service store;

  @tracked email = '';
  @tracked password = '';
  @tracked user = null;

  @tracked appointments = [];
  @tracked availabilityBlocks = [];

  @tracked loading = true;
  @tracked signingIn = false;

  @tracked errorMessage = '';
  @tracked successMessage = '';

  @tracked statusFilter = 'all';
  @tracked dateFilter = '';

  @tracked deletingConfirmation = '';
  @tracked deletingBlockId = '';

  @tracked blockDate = '';
  @tracked blockType = 'day';
  @tracked blockTime = '';
  @tracked blockReason = '';
  @tracked savingBlock = false;

  constructor(owner, args) {
    super(owner, args);

    this.initialize();
  }

  async initialize() {
    try {
      const user =
        await this.store.getCurrentUser();

      if (
        user &&
        user.email === ADMIN_EMAIL
      ) {
        this.user = user;

        await this.loadDashboardData();
      }
    } catch (error) {
      console.error(
        'Admin initialization error:',
        error,
      );
    } finally {
      this.loading = false;
    }
  }

  get blockTimeOptions() {
    return BLOCK_TIME_OPTIONS;
  }

  get pendingCount() {
    return this.appointments.filter(
      (appointment) =>
        appointment.status ===
        'pending',
    ).length;
  }

  get confirmedCount() {
    return this.appointments.filter(
      (appointment) =>
        appointment.status ===
        'confirmed',
    ).length;
  }

  get cancelledCount() {
    return this.appointments.filter(
      (appointment) =>
        appointment.status ===
        'cancelled',
    ).length;
  }

  get upcomingCount() {
    const today =
      this.getTodayString();

    return this.appointments.filter(
      (appointment) =>
        appointment.appointment_date >=
          today &&
        appointment.status !==
          'cancelled',
    ).length;
  }

  get filteredAppointments() {
    return this.appointments.filter(
      (appointment) => {
        const statusMatches =
          this.statusFilter === 'all' ||
          appointment.status ===
            this.statusFilter;

        const dateMatches =
          !this.dateFilter ||
          appointment.appointment_date ===
            this.dateFilter;

        return (
          statusMatches &&
          dateMatches
        );
      },
    );
  }

  get hasFilteredAppointments() {
    return (
      this.filteredAppointments.length >
      0
    );
  }

  get hasAvailabilityBlocks() {
    return (
      this.availabilityBlocks.length >
      0
    );
  }

  get isBlockingEntireDay() {
    return this.blockType === 'day';
  }

  get isBlockingSpecificTime() {
    return this.blockType === 'time';
  }

  get minimumBlockDate() {
    return this.getTodayString();
  }

  getTodayString() {
    const today = new Date();

    const year =
      today.getFullYear();

    const month =
      String(
        today.getMonth() + 1,
      ).padStart(
        2,
        '0',
      );

    const day =
      String(
        today.getDate(),
      ).padStart(
        2,
        '0',
      );

    return `${year}-${month}-${day}`;
  }

  updateEmail = (event) => {
    this.email =
      event.target.value;
  };

  updatePassword = (event) => {
    this.password =
      event.target.value;
  };

  updateStatusFilter = (event) => {
    this.statusFilter =
      event.target.value;
  };

  updateDateFilter = (event) => {
    this.dateFilter =
      event.target.value;
  };

  updateBlockDate = (event) => {
    this.blockDate =
      event.target.value;

    this.errorMessage = '';
    this.successMessage = '';
  };

  updateBlockType = (event) => {
    this.blockType =
      event.target.value;

    this.blockTime = '';
    this.errorMessage = '';
    this.successMessage = '';
  };

  updateBlockTime = (event) => {
    this.blockTime =
      event.target.value;

    this.errorMessage = '';
    this.successMessage = '';
  };

  updateBlockReason = (event) => {
    this.blockReason =
      event.target.value;
  };

  clearFilters = () => {
    this.statusFilter = 'all';
    this.dateFilter = '';
  };

  clearBlockForm = () => {
    this.blockDate = '';
    this.blockType = 'day';
    this.blockTime = '';
    this.blockReason = '';
  };

  signIn = async (event) => {
    event.preventDefault();

    if (this.signingIn) {
      return;
    }

    this.signingIn = true;

    this.errorMessage = '';
    this.successMessage = '';

    try {
      const user =
        await this.store.signIn(
          this.email,
          this.password,
        );

      if (
        !user ||
        user.email !== ADMIN_EMAIL
      ) {
        await this.store.signOut();

        throw new Error(
          'This account is not authorized to access the admin dashboard.',
        );
      }

      this.user = user;
      this.password = '';

      await this.loadDashboardData();
    } catch (error) {
      console.error(
        'Admin sign-in error:',
        error,
      );

      this.errorMessage =
        error?.message ||
        'Unable to sign in. Please check your email and password.';
    } finally {
      this.signingIn = false;
      this.loading = false;
    }
  };

  loadDashboardData = async () => {
    this.loading = true;
    this.errorMessage = '';

    try {
      const [
        appointments,
        availabilityBlocks,
      ] = await Promise.all([
        this.store.getAppointments(),

        this.store.getAvailabilityBlocks(),
      ]);

      this.appointments =
        this.prepareAppointments(
          appointments,
        );

      this.availabilityBlocks =
        this.prepareAvailabilityBlocks(
          availabilityBlocks,
        );
    } catch (error) {
      console.error(
        'Could not load dashboard:',
        error,
      );

      this.errorMessage =
        'Unable to load the dashboard. Please try again.';
    } finally {
      this.loading = false;
    }
  };

  loadAppointments = async () => {
    this.loading = true;
    this.errorMessage = '';

    try {
      const appointments =
        await this.store.getAppointments();

      this.appointments =
        this.prepareAppointments(
          appointments,
        );
    } catch (error) {
      console.error(
        'Could not load appointments:',
        error,
      );

      this.errorMessage =
        'Unable to load appointments. Please try again.';
    } finally {
      this.loading = false;
    }
  };

  loadAvailabilityBlocks = async () => {
    try {
      const blocks =
        await this.store.getAvailabilityBlocks();

      this.availabilityBlocks =
        this.prepareAvailabilityBlocks(
          blocks,
        );
    } catch (error) {
      console.error(
        'Could not load availability blocks:',
        error,
      );

      this.errorMessage =
        'Unable to load blocked availability.';
    }
  };

  prepareAppointments(
    appointments,
  ) {
    return appointments.map(
      (appointment) => ({
        ...appointment,

        displayDate:
          formatShortDate(
            appointment.appointment_date,
          ),

        serviceDuration:
          getServiceDuration(
            appointment.service,
          ),

        statusLabel:
          getStatusLabel(
            appointment.status,
          ),

        isPendingStatus:
          appointment.status ===
          'pending',

        isConfirmedStatus:
          appointment.status ===
          'confirmed',

        isDeleting:
          this.deletingConfirmation ===
          appointment.confirmation_number,
      }),
    );
  }

  prepareAvailabilityBlocks(
    blocks,
  ) {
    return blocks.map(
      (block) => ({
        ...block,

        displayDate:
          formatLongDate(
            block.block_date,
          ),

        isDayBlock:
          block.block_type ===
          'day',

        isTimeBlock:
          block.block_type ===
          'time',

        isDeleting:
          String(
            this.deletingBlockId,
          ) ===
          String(
            block.id,
          ),
      }),
    );
  }

  buildDayConflictMessage(
    conflicts,
  ) {
    if (!conflicts.length) {
      return '';
    }

    const appointments =
      conflicts.map(
        (appointment) => {
          const customerName =
            getCustomerName(
              appointment,
            );

          return `${customerName} at ${appointment.appointment_time}`;
        },
      );

    const appointmentWord =
      conflicts.length === 1
        ? 'appointment'
        : 'appointments';

    return (
      `You cannot block ${formatLongDate(this.blockDate)} because ` +
      `there ${conflicts.length === 1 ? 'is' : 'are'} already ` +
      `${conflicts.length} active ${appointmentWord}: ` +
      `${appointments.join(', ')}. ` +
      `Cancel or move the existing ${appointmentWord} first.`
    );
  }

  buildTimeConflictMessage(
    conflicts,
  ) {
    if (!conflicts.length) {
      return '';
    }

    const appointments =
      conflicts.map(
        (appointment) => {
          const customerName =
            getCustomerName(
              appointment,
            );

          return `${customerName} at ${appointment.appointment_time}`;
        },
      );

    if (conflicts.length === 1) {
      return (
        `You cannot block ${this.blockTime} on ` +
        `${formatLongDate(this.blockDate)} because it conflicts with ` +
        `${appointments[0]}. Cancel or move that appointment first.`
      );
    }

    return (
      `You cannot block ${this.blockTime} on ` +
      `${formatLongDate(this.blockDate)} because it conflicts with ` +
      `${conflicts.length} active appointments: ` +
      `${appointments.join(', ')}. ` +
      `Cancel or move those appointments first.`
    );
  }

  createAvailabilityBlock = async (
    event,
  ) => {
    event.preventDefault();

    if (this.savingBlock) {
      return;
    }

    this.errorMessage = '';
    this.successMessage = '';

    if (!this.blockDate) {
      this.errorMessage =
        'Please choose a date to block.';
      return;
    }

    if (
      this.blockDate <
      this.getTodayString()
    ) {
      this.errorMessage =
        'You cannot block a date in the past.';
      return;
    }

    const dateParts =
      this.blockDate.split('-');

    const selectedDate =
      new Date(
        Number(dateParts[0]),
        Number(dateParts[1]) - 1,
        Number(dateParts[2]),
      );

    if (
      selectedDate.getDay() === 0
    ) {
      this.errorMessage =
        'Sundays are already closed, so there is no need to block this date.';
      return;
    }

    if (
      this.blockType === 'time' &&
      !this.blockTime
    ) {
      this.errorMessage =
        'Please choose a time to block.';
      return;
    }

    this.savingBlock = true;

    try {
      if (
        this.blockType === 'day'
      ) {
        const conflicts =
          await this.store.getConflictingAppointments(
            this.blockDate,
          );

        if (
          conflicts.length >
          0
        ) {
          this.errorMessage =
            this.buildDayConflictMessage(
              conflicts,
            );

          return;
        }

        await this.store.blockEntireDay(
          this.blockDate,
          this.blockReason,
        );

        this.successMessage =
          `${formatLongDate(this.blockDate)} has been blocked for the entire day.`;
      } else {
        const conflicts =
          await this.store.getConflictingAppointments(
            this.blockDate,
            this.blockTime,
          );

        if (
          conflicts.length >
          0
        ) {
          this.errorMessage =
            this.buildTimeConflictMessage(
              conflicts,
            );

          return;
        }

        await this.store.blockTime(
          this.blockDate,
          this.blockTime,
          this.blockReason,
        );

        this.successMessage =
          `${this.blockTime} on ${formatLongDate(this.blockDate)} has been blocked.`;
      }

      this.clearBlockForm();

      await this.loadAvailabilityBlocks();
    } catch (error) {
      console.error(
        'Could not create availability block:',
        error,
      );

      if (
        error?.message ===
        'DAY_ALREADY_BLOCKED'
      ) {
        this.errorMessage =
          'That entire day is already blocked.';
      } else if (
        error?.message ===
        'TIME_ALREADY_BLOCKED'
      ) {
        this.errorMessage =
          'That appointment time is already blocked.';
      } else {
        this.errorMessage =
          'Unable to block that availability. Please try again.';
      }
    } finally {
      this.savingBlock = false;
    }
  };

  deleteAvailabilityBlock = async (
    event,
  ) => {
    if (this.deletingBlockId) {
      return;
    }

    const blockId =
      event.currentTarget.dataset
        .blockId;

    const block =
      this.availabilityBlocks.find(
        (item) =>
          String(item.id) ===
          String(blockId),
      );

    if (!block) {
      return;
    }

    const description =
      block.isDayBlock
        ? `the entire day on ${block.displayDate}`
        : `${block.block_time} on ${block.displayDate}`;

    const confirmed =
      window.confirm(
        `Remove the availability block for ${description}?`,
      );

    if (!confirmed) {
      return;
    }

    this.errorMessage = '';
    this.successMessage = '';

    this.deletingBlockId =
      blockId;

    this.availabilityBlocks =
      this.prepareAvailabilityBlocks(
        this.availabilityBlocks,
      );

    try {
      await this.store.deleteAvailabilityBlock(
        block.id,
      );

      this.successMessage =
        `The block for ${description} has been removed.`;

      await this.loadAvailabilityBlocks();
    } catch (error) {
      console.error(
        'Unable to delete availability block:',
        error,
      );

      this.errorMessage =
        'Unable to remove the availability block. Please try again.';
    } finally {
      this.deletingBlockId = '';

      this.availabilityBlocks =
        this.prepareAvailabilityBlocks(
          this.availabilityBlocks,
        );
    }
  };

  confirmAppointment = async (
    appointment,
  ) => {
    this.errorMessage = '';
    this.successMessage = '';

    try {
      await this.store.updateAppointmentStatus(
        appointment.confirmation_number,
        'confirmed',
      );

      try {
        await this.store.sendBookingStatusEmail(
          {
            ...appointment,
            status: 'confirmed',
          },
        );
      } catch (emailError) {
        console.error(
          'Appointment confirmation email error:',
          emailError,
        );

        this.successMessage =
          `${appointment.first_name}'s appointment has been confirmed, but the customer notification email could not be sent.`;

        await this.loadAppointments();
        return;
      }

      this.successMessage =
        `${appointment.first_name}'s appointment has been confirmed and the customer has been notified by email.`;

      await this.loadAppointments();
    } catch (error) {
      console.error(
        'Unable to confirm appointment:',
        error,
      );

      this.errorMessage =
        'Unable to confirm the appointment.';
    }
  };

  cancelAppointment = async (
    appointment,
  ) => {
    this.errorMessage = '';
    this.successMessage = '';

    try {
      await this.store.updateAppointmentStatus(
        appointment.confirmation_number,
        'cancelled',
      );

      try {
        await this.store.sendBookingStatusEmail(
          {
            ...appointment,
            status: 'cancelled',
          },
        );
      } catch (emailError) {
        console.error(
          'Appointment cancellation email error:',
          emailError,
        );

        this.successMessage =
          `${appointment.first_name}'s appointment has been cancelled, but the customer notification email could not be sent.`;

        await this.loadAppointments();
        return;
      }

      this.successMessage =
        `${appointment.first_name}'s appointment has been cancelled and the customer has been notified by email.`;

      await this.loadAppointments();
    } catch (error) {
      console.error(
        'Unable to cancel appointment:',
        error,
      );

      this.errorMessage =
        'Unable to cancel the appointment.';
    }
  };

  deleteAppointment = async (
    appointment,
  ) => {
    if (
      this.deletingConfirmation
    ) {
      return;
    }

    const customerName =
      `${appointment.first_name} ${appointment.last_name || ''}`.trim();

    const confirmed =
      window.confirm(
        `Are you sure you want to permanently delete ${customerName}'s appointment?\n\nThis cannot be undone.`,
      );

    if (!confirmed) {
      return;
    }

    this.errorMessage = '';
    this.successMessage = '';

    this.deletingConfirmation =
      appointment.confirmation_number;

    this.appointments =
      this.prepareAppointments(
        this.appointments,
      );

    try {
      await this.store.deleteAppointment(
        appointment.confirmation_number,
      );

      this.successMessage =
        `${customerName}'s appointment has been permanently deleted.`;

      await this.loadAppointments();
    } catch (error) {
      console.error(
        'Unable to delete appointment:',
        error,
      );

      this.errorMessage =
        'Unable to delete the appointment. Please try again.';
    } finally {
      this.deletingConfirmation = '';

      this.appointments =
        this.prepareAppointments(
          this.appointments,
        );
    }
  };

  handleConfirmClick = async (
    event,
  ) => {
    const confirmationNumber =
      event.currentTarget.dataset
        .confirmation;

    const appointment =
      this.appointments.find(
        (item) =>
          item.confirmation_number ===
          confirmationNumber,
      );

    if (appointment) {
      await this.confirmAppointment(
        appointment,
      );
    }
  };

  handleCancelClick = async (
    event,
  ) => {
    const confirmationNumber =
      event.currentTarget.dataset
        .confirmation;

    const appointment =
      this.appointments.find(
        (item) =>
          item.confirmation_number ===
          confirmationNumber,
      );

    if (appointment) {
      await this.cancelAppointment(
        appointment,
      );
    }
  };

  handleDeleteClick = async (
    event,
  ) => {
    const confirmationNumber =
      event.currentTarget.dataset
        .confirmation;

    const appointment =
      this.appointments.find(
        (item) =>
          item.confirmation_number ===
          confirmationNumber,
      );

    if (appointment) {
      await this.deleteAppointment(
        appointment,
      );
    }
  };

  logout = async () => {
    try {
      await this.store.signOut();

      this.user = null;
      this.appointments = [];
      this.availabilityBlocks = [];

      this.email = '';
      this.password = '';

      this.errorMessage = '';
      this.successMessage = '';

      this.statusFilter = 'all';
      this.dateFilter = '';

      this.clearBlockForm();
    } catch (error) {
      console.error(
        'Unable to sign out:',
        error,
      );

      this.errorMessage =
        'Unable to sign out.';
    }
  };

  <template>

    <style>

      .availability-manager {
        margin: 0 0 42px;
        padding: 32px;
        background: #fff;
        border: 1px solid #e5ddd7;
        box-shadow:
          0 15px 45px
          rgba(35, 25, 20, 0.05);
      }

      .availability-manager-header {
        margin-bottom: 26px;
        display: flex;
        align-items: flex-end;
        justify-content: space-between;
        gap: 25px;
      }

      .availability-manager-header h2 {
        margin: 3px 0 7px;
        font-family:
          'Cormorant Garamond',
          Georgia,
          serif;
        font-size: 38px;
        font-weight: 500;
        line-height: 1;
      }

      .availability-manager-header p {
        max-width: 680px;
        margin: 0;
        color: #83766f;
        font-size: 13px;
        line-height: 1.7;
      }

      .availability-label {
        display: block;
        color: #8c7163;
        font-size: 10px;
        font-weight: 600;
        letter-spacing: 0.14em;
        text-transform: uppercase;
      }

      .availability-form {
        padding: 24px;
        background: #f9f6f3;
        border: 1px solid #ebe3dd;
      }

      .availability-form-grid {
        display: grid;
        grid-template-columns:
          repeat(
            3,
            minmax(0, 1fr)
          );
        gap: 18px;
      }

      .availability-field {
        min-width: 0;
      }

      .availability-field label {
        display: block;
        margin-bottom: 7px;
        color: #52443e;
        font-size: 10px;
        font-weight: 600;
        letter-spacing: 0.09em;
        text-transform: uppercase;
      }

      .availability-field input,
      .availability-field select,
      .availability-field textarea {
        width: 100%;
        min-width: 0;
        padding: 12px 13px;
        border: 1px solid #ddd3cc;
        border-radius: 0;
        outline: none;
        background: #fff;
        color: #241b18;
        font-family: inherit;
        font-size: 14px;
      }

      .availability-field input,
      .availability-field select {
        min-height: 48px;
      }

      .availability-field textarea {
        min-height: 90px;
        resize: vertical;
      }

      .availability-field input:focus,
      .availability-field select:focus,
      .availability-field textarea:focus {
        border-color: #8d6f60;
      }

      .availability-reason {
        margin-top: 18px;
      }

      .availability-actions {
        margin-top: 18px;
        display: flex;
        align-items: center;
        flex-wrap: wrap;
        gap: 10px;
      }

      .availability-save {
        min-height: 46px;
        padding: 0 22px;
        border: 0;
        background: #241b18;
        color: #fff;
        cursor: pointer;
        font-size: 10px;
        font-weight: 600;
        letter-spacing: 0.09em;
        text-transform: uppercase;
      }

      .availability-save:hover {
        background: #493a34;
      }

      .availability-save:disabled {
        cursor: wait;
        opacity: 0.6;
      }

      .availability-reset {
        min-height: 46px;
        padding: 0 20px;
        border: 1px solid #d7cbc4;
        background: transparent;
        color: #594941;
        cursor: pointer;
        font-size: 10px;
        font-weight: 600;
        letter-spacing: 0.08em;
        text-transform: uppercase;
      }

      .availability-current {
        margin-top: 30px;
      }

      .availability-current-heading {
        margin-bottom: 14px;
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 20px;
      }

      .availability-current-heading h3 {
        margin: 0;
        font-family:
          'Cormorant Garamond',
          Georgia,
          serif;
        font-size: 27px;
        font-weight: 500;
      }

      .availability-count {
        color: #95827a;
        font-size: 11px;
        letter-spacing: 0.08em;
        text-transform: uppercase;
      }

      .availability-block-list {
        display: grid;
        gap: 10px;
      }

      .availability-block {
        padding: 16px 18px;
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 20px;
        border: 1px solid #e8dfd9;
        background: #fff;
      }

      .availability-block-main {
        min-width: 0;
        display: flex;
        align-items: center;
        gap: 18px;
      }

      .availability-block-type {
        min-width: 90px;
        padding: 7px 10px;
        background: #f2ebe7;
        color: #705a50;
        font-size: 9px;
        font-weight: 700;
        letter-spacing: 0.09em;
        text-align: center;
        text-transform: uppercase;
      }

      .availability-block-info {
        min-width: 0;
      }

      .availability-block-info strong {
        display: block;
        color: #241b18;
        font-family:
          'Cormorant Garamond',
          Georgia,
          serif;
        font-size: 21px;
        font-weight: 500;
        line-height: 1.2;
      }

      .availability-block-info span {
        display: block;
        margin-top: 3px;
        color: #806f67;
        font-size: 12px;
      }

      .availability-block-info p {
        margin: 6px 0 0;
        color: #9b8980;
        font-size: 11px;
        line-height: 1.5;
      }

      .availability-remove {
        flex-shrink: 0;
        min-height: 40px;
        padding: 0 15px;
        border: 1px solid #e0c6c6;
        background: #fff7f7;
        color: #a34d4d;
        cursor: pointer;
        font-size: 9px;
        font-weight: 600;
        letter-spacing: 0.08em;
        text-transform: uppercase;
      }

      .availability-remove:hover {
        background: #a34d4d;
        color: #fff;
      }

      .availability-remove:disabled {
        cursor: wait;
        opacity: 0.5;
      }

      .availability-empty {
        padding: 24px;
        background: #f9f6f3;
        border: 1px dashed #d9cec7;
        color: #8c7a72;
        font-size: 13px;
        text-align: center;
      }

      .availability-help {
        margin-top: 17px;
        padding-top: 17px;
        border-top: 1px solid #e5ddd7;
        color: #93827a;
        font-size: 11px;
        line-height: 1.7;
      }

      @media (max-width: 850px) {

        .availability-form-grid {
          grid-template-columns:
            repeat(
              2,
              minmax(0, 1fr)
            );
        }

      }

      @media (max-width: 650px) {

        .availability-manager {
          padding: 22px 16px;
        }

        .availability-manager-header {
          align-items: flex-start;
          flex-direction: column;
        }

        .availability-manager-header h2 {
          font-size: 32px;
        }

        .availability-form {
          padding: 17px;
        }

        .availability-form-grid {
          grid-template-columns: 1fr;
        }

        .availability-block {
          align-items: flex-start;
          flex-direction: column;
        }

        .availability-block-main {
          width: 100%;
          align-items: flex-start;
          flex-direction: column;
          gap: 9px;
        }

        .availability-remove {
          width: 100%;
        }

        .availability-actions {
          flex-direction: column;
        }

        .availability-save,
        .availability-reset {
          width: 100%;
        }

      }

    </style>


    <div class="admin-page">

      {{#if this.loading}}

        <div class="admin-loading">

          <div class="admin-spinner"></div>

          <p>
            Loading...
          </p>

        </div>


      {{else if this.user}}

        <header class="admin-header">

          <div class="admin-header-inner">

            <a
              href="/"
              class="admin-logo"
            >

              <img
                src="/assets/images/lashes-logo.png"
                alt="Lashes by Mariia"
              />

            </a>


            <div class="admin-header-right">

              <div class="admin-user-info">

                <span class="admin-user-label">
                  Signed in as
                </span>

                <span class="admin-user">
                  {{this.user.email}}
                </span>

              </div>


              <button
                type="button"
                class="admin-logout"
                onclick={{this.logout}}
              >
                Sign Out
              </button>

            </div>

          </div>

        </header>


        <main class="admin-main">

          <div class="admin-title-row">

            <div>

              <p class="eyebrow">
                LASHES BY MARIIA
              </p>

              <h1>
                Appointments
              </h1>

              <p>
                Manage your appointment requests,
                schedule and availability.
              </p>

            </div>


            <button
              type="button"
              class="admin-refresh"
              onclick={{this.loadDashboardData}}
            >
              ↻ Refresh
            </button>

          </div>


          {{#if this.successMessage}}

            <div class="admin-success">
              ✓ {{this.successMessage}}
            </div>

          {{/if}}


          {{#if this.errorMessage}}

            <div class="admin-error">
              {{this.errorMessage}}
            </div>

          {{/if}}


          <div class="admin-stats">

            <div class="admin-stat">

              <span>
                Total
              </span>

              <strong>
                {{this.appointments.length}}
              </strong>

            </div>


            <div class="admin-stat">

              <span>
                Upcoming
              </span>

              <strong>
                {{this.upcomingCount}}
              </strong>

            </div>


            <div class="admin-stat">

              <span>
                Pending
              </span>

              <strong>
                {{this.pendingCount}}
              </strong>

            </div>


            <div class="admin-stat">

              <span>
                Confirmed
              </span>

              <strong>
                {{this.confirmedCount}}
              </strong>

            </div>


            <div class="admin-stat">

              <span>
                Cancelled
              </span>

              <strong>
                {{this.cancelledCount}}
              </strong>

            </div>

          </div>


          {{!-- ============================================
               AVAILABILITY MANAGER
          ============================================= --}}

          <section class="availability-manager">

            <div class="availability-manager-header">

              <div>

                <span class="availability-label">
                  SCHEDULE CONTROL
                </span>

                <h2>
                  Manage Availability
                </h2>

                <p>
                  Block an entire day or a specific
                  appointment time. Blocked availability
                  automatically disappears from the
                  customer booking page.
                </p>

              </div>

            </div>


            <form
              class="availability-form"
              onsubmit={{this.createAvailabilityBlock}}
            >

              <div class="availability-form-grid">

                <div class="availability-field">

                  <label for="block-date">
                    Date
                  </label>

                  <input
                    id="block-date"
                    type="date"
                    min={{this.minimumBlockDate}}
                    value={{this.blockDate}}
                    onchange={{this.updateBlockDate}}
                    required
                  />

                </div>


                <div class="availability-field">

                  <label for="block-type">
                    What do you want to block?
                  </label>

                  <select
                    id="block-type"
                    value={{this.blockType}}
                    onchange={{this.updateBlockType}}
                  >

                    <option value="day">
                      Entire Day
                    </option>

                    <option value="time">
                      Specific Time
                    </option>

                  </select>

                </div>


                {{#if this.isBlockingSpecificTime}}

                  <div class="availability-field">

                    <label for="block-time">
                      Appointment Time
                    </label>

                    <select
                      id="block-time"
                      value={{this.blockTime}}
                      onchange={{this.updateBlockTime}}
                      required
                    >

                      <option value="">
                        Select a time
                      </option>


                      {{#each this.blockTimeOptions as |time|}}

                        <option value={{time}}>
                          {{time}}
                        </option>

                      {{/each}}

                    </select>

                  </div>

                {{else}}

                  <div class="availability-field">

                    <label>
                      Hours Being Blocked
                    </label>

                    <input
                      type="text"
                      value="9:00 AM – 6:00 PM"
                      disabled
                    />

                  </div>

                {{/if}}

              </div>


              <div
                class="availability-field availability-reason"
              >

                <label for="block-reason">
                  Note / Reason
                  (Optional)
                </label>

                <textarea
                  id="block-reason"
                  placeholder="Vacation, personal appointment, unavailable, etc."
                  value={{this.blockReason}}
                  oninput={{this.updateBlockReason}}
                ></textarea>

              </div>


              <div class="availability-actions">

                <button
                  type="submit"
                  class="availability-save"
                  disabled={{this.savingBlock}}
                >

                  {{#if this.savingBlock}}

                    Checking...

                  {{else if this.isBlockingEntireDay}}

                    Block Entire Day

                  {{else}}

                    Block Appointment Time

                  {{/if}}

                </button>


                <button
                  type="button"
                  class="availability-reset"
                  onclick={{this.clearBlockForm}}
                >
                  Clear
                </button>

              </div>

            </form>


            <div class="availability-current">

              <div class="availability-current-heading">

                <h3>
                  Current Blocks
                </h3>

                <span class="availability-count">
                  {{this.availabilityBlocks.length}}
                  active
                </span>

              </div>


              {{#if this.hasAvailabilityBlocks}}

                <div class="availability-block-list">

                  {{#each this.availabilityBlocks as |block|}}

                    <article class="availability-block">

                      <div class="availability-block-main">

                        <span class="availability-block-type">

                          {{#if block.isDayBlock}}

                            Full Day

                          {{else}}

                            Time

                          {{/if}}

                        </span>


                        <div class="availability-block-info">

                          <strong>
                            {{block.displayDate}}
                          </strong>


                          {{#if block.isDayBlock}}

                            <span>
                              Entire day blocked
                              ·
                              9:00 AM – 6:00 PM
                            </span>

                          {{else}}

                            <span>
                              {{block.block_time}}
                              appointment blocked
                            </span>

                          {{/if}}


                          {{#if block.reason}}

                            <p>
                              {{block.reason}}
                            </p>

                          {{/if}}

                        </div>

                      </div>


                      <button
                        type="button"
                        class="availability-remove"
                        data-block-id={{block.id}}
                        onclick={{this.deleteAvailabilityBlock}}
                        disabled={{block.isDeleting}}
                      >

                        {{#if block.isDeleting}}

                          Removing...

                        {{else}}

                          Remove Block

                        {{/if}}

                      </button>

                    </article>

                  {{/each}}

                </div>

              {{else}}

                <div class="availability-empty">

                  No days or appointment times
                  are currently blocked.

                </div>

              {{/if}}


              <p class="availability-help">

                Regular booking hours are Monday through
                Saturday, 9:00 AM–6:00 PM. Sunday is
                automatically closed and does not need
                to be blocked manually.

              </p>

            </div>

          </section>


          {{!-- ============================================
               APPOINTMENT FILTERS
          ============================================= --}}

          <section class="admin-filters">

            <div class="admin-filter-heading">

              <div>

                <span class="admin-filter-label">
                  APPOINTMENT SCHEDULE
                </span>

                <strong>
                  {{this.filteredAppointments.length}}
                  appointments
                </strong>

              </div>


              <button
                type="button"
                class="admin-clear-filters"
                onclick={{this.clearFilters}}
              >
                Clear Filters
              </button>

            </div>


            <div class="admin-filter-controls">

              <div class="admin-filter-field">

                <label for="appointment-status-filter">
                  Status
                </label>

                <select
                  id="appointment-status-filter"
                  value={{this.statusFilter}}
                  onchange={{this.updateStatusFilter}}
                >

                  <option value="all">
                    All appointments
                  </option>

                  <option value="pending">
                    Pending
                  </option>

                  <option value="confirmed">
                    Confirmed
                  </option>

                  <option value="cancelled">
                    Cancelled
                  </option>

                </select>

              </div>


              <div class="admin-filter-field">

                <label for="appointment-date-filter">
                  Date
                </label>

                <input
                  id="appointment-date-filter"
                  type="date"
                  value={{this.dateFilter}}
                  onchange={{this.updateDateFilter}}
                />

              </div>

            </div>

          </section>


          {{!-- ============================================
               APPOINTMENT LIST
          ============================================= --}}

          {{#if this.hasFilteredAppointments}}

            <div class="appointment-list">

              {{#each this.filteredAppointments as |appointment|}}

                <article class="admin-appointment">

                  <div class="appointment-main">

                    <div class="appointment-date">

                      <span>
                        {{appointment.displayDate}}
                      </span>

                      <strong>
                        {{appointment.appointment_time}}
                      </strong>

                      <small>
                        {{appointment.serviceDuration}}
                      </small>

                    </div>


                    <div class="appointment-customer">

                      <div class="appointment-name-row">

                        <h2>
                          {{appointment.first_name}}
                          {{appointment.last_name}}
                        </h2>


                        <span class="appointment-status">
                          {{appointment.statusLabel}}
                        </span>

                      </div>


                      <p class="appointment-service">
                        {{appointment.service}}
                      </p>


                      <div class="appointment-contact">

                        <a
                          href="mailto:{{appointment.email}}"
                        >
                          ✉ {{appointment.email}}
                        </a>


                        <a
                          href="tel:{{appointment.phone}}"
                        >
                          ☎ {{appointment.phone}}
                        </a>

                      </div>


                      {{#if appointment.message}}

                        <div class="appointment-message">

                          <span>
                            CUSTOMER MESSAGE
                          </span>

                          <p>
                            {{appointment.message}}
                          </p>

                        </div>

                      {{/if}}


                      <small class="appointment-confirmation">

                        Confirmation:
                        {{appointment.confirmation_number}}

                      </small>

                    </div>

                  </div>


                  <div class="appointment-actions">

                    {{#if appointment.isPendingStatus}}

                      <button
                        type="button"
                        class="admin-confirm"
                        data-confirmation={{appointment.confirmation_number}}
                        onclick={{this.handleConfirmClick}}
                      >
                        ✓ Confirm
                      </button>


                      <button
                        type="button"
                        class="admin-cancel"
                        data-confirmation={{appointment.confirmation_number}}
                        onclick={{this.handleCancelClick}}
                      >
                        Cancel
                      </button>


                    {{else if appointment.isConfirmedStatus}}

                      <a
                        href="mailto:{{appointment.email}}?subject=Your%20Lashes%20by%20Mariia%20appointment"
                        class="admin-email"
                      >
                        ✉ Email
                      </a>


                      <button
                        type="button"
                        class="admin-cancel"
                        data-confirmation={{appointment.confirmation_number}}
                        onclick={{this.handleCancelClick}}
                      >
                        Cancel
                      </button>


                    {{else}}

                      <a
                        href="mailto:{{appointment.email}}"
                        class="admin-email"
                      >
                        ✉ Email
                      </a>

                    {{/if}}


                    <button
                      type="button"
                      class="admin-delete"
                      data-confirmation={{appointment.confirmation_number}}
                      onclick={{this.handleDeleteClick}}
                      disabled={{appointment.isDeleting}}
                    >

                      {{#if appointment.isDeleting}}

                        Deleting...

                      {{else}}

                        🗑 Delete

                      {{/if}}

                    </button>

                  </div>

                </article>

              {{/each}}

            </div>


          {{else}}

            <div class="admin-empty">

              <div class="admin-empty-icon">
                ♡
              </div>


              <h2>

                {{#if this.appointments.length}}

                  No appointments match
                  your filters

                {{else}}

                  No appointments yet

                {{/if}}

              </h2>


              <p>

                {{#if this.appointments.length}}

                  Try changing the status
                  or date filter.

                {{else}}

                  New appointment requests
                  will appear here.

                {{/if}}

              </p>


              {{#if this.appointments.length}}

                <button
                  type="button"
                  class="admin-refresh"
                  onclick={{this.clearFilters}}
                >
                  Clear Filters
                </button>

              {{/if}}

            </div>

          {{/if}}

        </main>


      {{else}}

        <main class="admin-login-page">

          <div class="admin-login-card">

            <a
              href="/"
              class="admin-login-logo"
            >

              <img
                src="/assets/images/lashes-logo.png"
                alt="Lashes by Mariia"
              />

            </a>


            <p class="eyebrow">
              PRIVATE AREA
            </p>


            <h1>
              Admin Login
            </h1>


            <p class="admin-login-description">

              Sign in to manage Lashes by
              Mariia appointments and
              availability.

            </p>


            <form
              class="admin-login-form"
              onsubmit={{this.signIn}}
            >

              <label for="admin-email">
                Email
              </label>

              <input
                id="admin-email"
                type="email"
                placeholder="Email address"
                autocomplete="email"
                value={{this.email}}
                oninput={{this.updateEmail}}
                required
              />


              <label for="admin-password">
                Password
              </label>

              <input
                id="admin-password"
                type="password"
                placeholder="Password"
                autocomplete="current-password"
                value={{this.password}}
                oninput={{this.updatePassword}}
                required
              />


              {{#if this.errorMessage}}

                <div class="admin-error">
                  {{this.errorMessage}}
                </div>

              {{/if}}


              <button
                type="submit"
                class="button button-primary admin-login-button"
                disabled={{this.signingIn}}
              >

                {{#if this.signingIn}}

                  Signing In...

                {{else}}

                  Sign In

                {{/if}}

              </button>

            </form>


            <a
              href="/"
              class="back-to-site"
            >
              ← Back to website
            </a>

          </div>

        </main>

      {{/if}}

    </div>

  </template>
}
