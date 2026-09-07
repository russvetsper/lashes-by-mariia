import Service from '@ember/service';
import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL =
  'https://berybsxlvbvywxwhvjzj.supabase.co';

const SUPABASE_KEY =
  'sb_publishable_RN884x19HtIyaZV6UxZupw_uk9KkyCr';

const STORAGE_KEY =
  'lashes-by-mariia-appointments';

const BUSINESS_OPEN_HOUR = 9;
const BUSINESS_CLOSE_HOUR = 18;

const SERVICE_DURATION_MINUTES = 45;

const supabase = createClient(
  SUPABASE_URL,
  SUPABASE_KEY,
);

export default class StoreService extends Service {
  async getAppointments() {
    const { data, error } =
      await supabase
        .from('appointments')
        .select('*')
        .order('appointment_date', {
          ascending: true,
        })
        .order('appointment_time', {
          ascending: true,
        });

    if (error) {
      console.error(
        'Could not load appointments:',
        error,
      );

      throw error;
    }

    return data || [];
  }

  async getAvailabilityBlocks() {
    const { data, error } =
      await supabase
        .from('availability_blocks')
        .select('*')
        .order('block_date', {
          ascending: true,
        })
        .order('block_time', {
          ascending: true,
        });

    if (error) {
      console.error(
        'Could not load availability blocks:',
        error,
      );

      throw error;
    }

    return data || [];
  }

  async getAvailabilityBlocksForDate(date) {
    if (!date) {
      return [];
    }

    const { data, error } =
      await supabase
        .from('availability_blocks')
        .select('*')
        .eq(
          'block_date',
          date,
        )
        .order('block_time', {
          ascending: true,
        });

    if (error) {
      console.error(
        'Could not load availability blocks for date:',
        error,
      );

      throw error;
    }

    return data || [];
  }

  async blockEntireDay(
    date,
    reason = '',
  ) {
    if (!date) {
      throw new Error(
        'A date is required.',
      );
    }

    const { data, error } =
      await supabase
        .from('availability_blocks')
        .insert({
          block_date: date,
          block_time: null,
          block_type: 'day',
          reason: reason || null,
        })
        .select()
        .single();

    if (error) {
      console.error(
        'Could not block day:',
        error,
      );

      if (
        error.code === '23505'
      ) {
        throw new Error(
          'DAY_ALREADY_BLOCKED',
        );
      }

      throw error;
    }

    return data;
  }

  async blockTime(
    date,
    time,
    reason = '',
  ) {
    if (!date || !time) {
      throw new Error(
        'A date and time are required.',
      );
    }

    const { data, error } =
      await supabase
        .from('availability_blocks')
        .insert({
          block_date: date,
          block_time: time,
          block_type: 'time',
          reason: reason || null,
        })
        .select()
        .single();

    if (error) {
      console.error(
        'Could not block time:',
        error,
      );

      if (
        error.code === '23505'
      ) {
        throw new Error(
          'TIME_ALREADY_BLOCKED',
        );
      }

      throw error;
    }

    return data;
  }

  async deleteAvailabilityBlock(id) {
    if (!id) {
      throw new Error(
        'Missing availability block ID.',
      );
    }

    const { error } =
      await supabase
        .from('availability_blocks')
        .delete()
        .eq(
          'id',
          id,
        );

    if (error) {
      console.error(
        'Could not delete availability block:',
        error,
      );

      throw error;
    }

    return true;
  }

  async getAvailableTimes(date, service) {
    if (!date || !service) {
      return [];
    }

    if (
      service !==
      'Lash Lift & Lash Lamination'
    ) {
      return [];
    }

    const selectedDate =
      this.parseDateString(date);

    if (!selectedDate) {
      return [];
    }

    const dayOfWeek =
      selectedDate.getDay();

    if (dayOfWeek === 0) {
      return [];
    }

    const today = new Date();

    const todayString =
      this.formatDateForDatabase(today);

    if (date < todayString) {
      return [];
    }

    const [
      bookedAppointments,
      availabilityBlocks,
    ] = await Promise.all([
      this.getAppointmentsForDate(
        date,
      ),

      this.getAvailabilityBlocksForDate(
        date,
      ),
    ]);

    const fullDayBlocked =
      availabilityBlocks.some(
        (block) =>
          block.block_type ===
          'day',
      );

    if (fullDayBlocked) {
      return [];
    }

    const blockedTimes =
      availabilityBlocks
        .filter(
          (block) =>
            block.block_type ===
              'time' &&
            block.block_time,
        )
        .map(
          (block) =>
            block.block_time,
        );

    const slotMinutes = [];

    const startMinutes =
      BUSINESS_OPEN_HOUR * 60;

    const closeMinutes =
      BUSINESS_CLOSE_HOUR * 60;

    for (
      let minutes = startMinutes;
      minutes < closeMinutes;
      minutes += SERVICE_DURATION_MINUTES
    ) {
      slotMinutes.push(minutes);
    }

    if (
      !slotMinutes.includes(
        closeMinutes,
      )
    ) {
      slotMinutes.push(
        closeMinutes,
      );
    }

    const availableTimes = [];

    for (const minutes of slotMinutes) {
      if (
        date === todayString &&
        this.isTimeInPast(minutes)
      ) {
        continue;
      }

      const displayTime =
        this.minutesToDisplayTime(
          minutes,
        );

      const isBlocked =
        blockedTimes.some(
          (blockedTime) =>
            this.normalizeTime(
              blockedTime,
            ) ===
            this.normalizeTime(
              displayTime,
            ),
        );

      if (isBlocked) {
        continue;
      }

      const isBooked =
        bookedAppointments.some(
          (appointment) =>
            this.appointmentBlocksTime(
              appointment,
              minutes,
            ),
        );

      if (!isBooked) {
        availableTimes.push(
          displayTime,
        );
      }
    }

    return availableTimes;
  }

  async isTimeAvailable(
    date,
    time,
    service,
  ) {
    if (
      !date ||
      !time ||
      !service
    ) {
      return false;
    }

    const availableTimes =
      await this.getAvailableTimes(
        date,
        service,
      );

    return availableTimes.includes(
      time,
    );
  }

  async getAppointmentsForDate(date) {
    if (!date) {
      return [];
    }

    const { data, error } =
      await supabase
        .from('appointments')
        .select('*')
        .eq(
          'appointment_date',
          date,
        )
        .order(
          'appointment_time',
          {
            ascending: true,
          },
        );

    if (error) {
      console.error(
        'Could not load appointments for date:',
        error,
      );

      throw error;
    }

    return (data || []).filter(
      (appointment) =>
        appointment.status !==
        'cancelled',
    );
  }

  async getConflictingAppointments(
    date,
    time = null,
  ) {
    if (!date) {
      return [];
    }

    const appointments =
      await this.getAppointmentsForDate(
        date,
      );

    /*
     * No time means the admin is trying
     * to block the entire day.
     *
     * Every active appointment on that
     * date is therefore a conflict.
     */
    if (!time) {
      return appointments;
    }

    const requestedStartMinutes =
      this.timeToMinutes(time);

    if (
      requestedStartMinutes === null
    ) {
      return [];
    }

    return appointments.filter(
      (appointment) =>
        this.appointmentBlocksTime(
          appointment,
          requestedStartMinutes,
        ),
    );
  }

  appointmentBlocksTime(
    appointment,
    requestedStartMinutes,
  ) {
    const appointmentStart =
      this.timeToMinutes(
        appointment.appointment_time,
      );

    if (
      appointmentStart === null
    ) {
      return false;
    }

    const appointmentDuration =
      this.getServiceDuration(
        appointment.service,
      );

    const appointmentEnd =
      appointmentStart +
      appointmentDuration;

    const requestedEnd =
      requestedStartMinutes +
      SERVICE_DURATION_MINUTES;

    return (
      requestedStartMinutes <
        appointmentEnd &&
      requestedEnd >
        appointmentStart
    );
  }

  getServiceDuration(service) {
    if (
      service ===
      'Lash Lift & Lash Lamination'
    ) {
      return 45;
    }

    if (
      service ===
      'Classic Full Set'
    ) {
      return 135;
    }

    if (
      service ===
      'Hybrid Full Set'
    ) {
      return 150;
    }

    if (
      service ===
      'Volume Full Set'
    ) {
      return 165;
    }

    if (
      service ===
      'Lash Fill'
    ) {
      return 90;
    }

    return 45;
  }

  normalizeTime(time) {
    const minutes =
      this.timeToMinutes(time);

    if (minutes === null) {
      return String(time)
        .trim()
        .toUpperCase();
    }

    return this.minutesToDisplayTime(
      minutes,
    );
  }

  timeToMinutes(time) {
    if (!time) {
      return null;
    }

    const trimmed =
      String(time)
        .trim()
        .toUpperCase();

    const twelveHourMatch =
      trimmed.match(
        /^(\d{1,2}):(\d{2})\s*(AM|PM)$/,
      );

    if (twelveHourMatch) {
      let hour =
        Number(
          twelveHourMatch[1],
        );

      const minute =
        Number(
          twelveHourMatch[2],
        );

      const meridiem =
        twelveHourMatch[3];

      if (
        hour < 1 ||
        hour > 12 ||
        minute < 0 ||
        minute > 59
      ) {
        return null;
      }

      if (
        meridiem === 'AM' &&
        hour === 12
      ) {
        hour = 0;
      }

      if (
        meridiem === 'PM' &&
        hour !== 12
      ) {
        hour += 12;
      }

      return hour * 60 + minute;
    }

    const twentyFourHourMatch =
      trimmed.match(
        /^(\d{1,2}):(\d{2})$/,
      );

    if (twentyFourHourMatch) {
      const hour =
        Number(
          twentyFourHourMatch[1],
        );

      const minute =
        Number(
          twentyFourHourMatch[2],
        );

      if (
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59
      ) {
        return null;
      }

      return hour * 60 + minute;
    }

    return null;
  }

  minutesToDisplayTime(
    totalMinutes,
  ) {
    const hour24 =
      Math.floor(
        totalMinutes / 60,
      );

    const minute =
      totalMinutes % 60;

    const meridiem =
      hour24 >= 12
        ? 'PM'
        : 'AM';

    let hour12 =
      hour24 % 12;

    if (hour12 === 0) {
      hour12 = 12;
    }

    return `${hour12}:${String(
      minute,
    ).padStart(
      2,
      '0',
    )} ${meridiem}`;
  }

  isTimeInPast(
    startMinutes,
  ) {
    const now =
      new Date();

    const currentMinutes =
      now.getHours() * 60 +
      now.getMinutes();

    return (
      startMinutes <=
      currentMinutes
    );
  }

  parseDateString(dateString) {
    const match =
      String(dateString).match(
        /^(\d{4})-(\d{2})-(\d{2})$/,
      );

    if (!match) {
      return null;
    }

    const year =
      Number(match[1]);

    const month =
      Number(match[2]) - 1;

    const day =
      Number(match[3]);

    const date =
      new Date(
        year,
        month,
        day,
      );

    if (
      date.getFullYear() !== year ||
      date.getMonth() !== month ||
      date.getDate() !== day
    ) {
      return null;
    }

    return date;
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

  async saveAppointment(
    appointment,
  ) {
    const confirmationNumber =
      `LBM-${Date.now()}`;

    const databaseAppointment = {
      confirmation_number:
        confirmationNumber,

      first_name:
        appointment.firstName,

      last_name:
        appointment.lastName,

      email:
        appointment.email,

      phone:
        appointment.phone,

      service:
        appointment.service,

      appointment_date:
        appointment.date,

      appointment_time:
        appointment.time,

      message:
        appointment.message || '',

      status:
        'pending',
    };

    const { error } =
      await supabase
        .from('appointments')
        .insert(
          databaseAppointment,
        );

    if (error) {
      console.error(
        'Supabase appointment error:',
        error,
      );

      if (
        error.code === '23505'
      ) {
        throw new Error(
          'TIME_ALREADY_BOOKED',
        );
      }

      throw error;
    }

    if (
      typeof window !==
      'undefined'
    ) {
      try {
        const localAppointments =
          JSON.parse(
            window.localStorage.getItem(
              STORAGE_KEY,
            ) || '[]',
          );

        localAppointments.push({
          ...appointment,
          confirmationNumber,
        });

        window.localStorage.setItem(
          STORAGE_KEY,
          JSON.stringify(
            localAppointments,
          ),
        );
      } catch (error) {
        console.warn(
          'Local backup failed:',
          error,
        );
      }
    }

    return {
      id:
        confirmationNumber,

      confirmation_number:
        confirmationNumber,

      ...appointment,
    };
  }

  async sendBookingEmail(
    appointment,
  ) {
    const { data, error } =
      await supabase.functions.invoke(
        'send-booking-email',
        {
          body:
            appointment,
        },
      );

    if (error) {
      console.error(
        'Could not send booking email:',
        error,
      );

      throw error;
    }

    if (data?.error) {
      throw new Error(
        data.error,
      );
    }

    return data;
  }

  async sendBookingStatusEmail(
    appointment,
  ) {
    const { data, error } =
      await supabase.functions.invoke(
        'send-booking-status-email',
        {
          body:
            appointment,
        },
      );

    if (error) {
      console.error(
        'Could not send booking status email:',
        error,
      );

      throw error;
    }

    if (data?.error) {
      throw new Error(
        data.error,
      );
    }

    return data;
  }

  async getCurrentUser() {
    const { data, error } =
      await supabase.auth.getUser();

    if (error) {
      return null;
    }

    return data.user || null;
  }

  async signIn(
    email,
    password,
  ) {
    const { data, error } =
      await supabase.auth
        .signInWithPassword({
          email,
          password,
        });

    if (error) {
      throw error;
    }

    return data.user;
  }

  async signOut() {
    const { error } =
      await supabase.auth.signOut();

    if (error) {
      throw error;
    }
  }

  async updateAppointmentStatus(
    confirmationNumber,
    status,
  ) {
    const { data, error } =
      await supabase
        .from('appointments')
        .update({
          status,
        })
        .eq(
          'confirmation_number',
          confirmationNumber,
        )
        .select()
        .single();

    if (error) {
      console.error(
        'Could not update appointment:',
        error,
      );

      throw error;
    }

    return data;
  }

  async deleteAppointment(
    confirmationNumber,
  ) {
    if (!confirmationNumber) {
      throw new Error(
        'Missing appointment confirmation number.',
      );
    }

    const { error } =
      await supabase
        .from('appointments')
        .delete()
        .eq(
          'confirmation_number',
          confirmationNumber,
        );

    if (error) {
      console.error(
        'Could not delete appointment:',
        error,
      );

      throw error;
    }

    if (
      typeof window !==
      'undefined'
    ) {
      try {
        const localAppointments =
          JSON.parse(
            window.localStorage.getItem(
              STORAGE_KEY,
            ) || '[]',
          );

        const updatedAppointments =
          localAppointments.filter(
            (appointment) =>
              appointment.confirmationNumber !==
              confirmationNumber,
          );

        window.localStorage.setItem(
          STORAGE_KEY,
          JSON.stringify(
            updatedAppointments,
          ),
        );
      } catch (error) {
        console.warn(
          'Local appointment cleanup failed:',
          error,
        );
      }
    }

    return true;
  }

  clearAppointments() {
    if (
      typeof window !==
      'undefined'
    ) {
      window.localStorage.removeItem(
        STORAGE_KEY,
      );
    }
  }
}
