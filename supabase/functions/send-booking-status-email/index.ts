import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY');

const ADMIN_EMAIL = 'lashesmariia@gmail.com';

const FROM_EMAIL =
  'Lashes by Mariia <appointments@lashesbymariia.com>';

function escapeHtml(value: unknown) {
  return String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers':
          'authorization, x-client-info, apikey, content-type',
        'Access-Control-Allow-Methods':
          'POST, OPTIONS',
      },
    });
  }

  try {
    if (!RESEND_API_KEY) {
      throw new Error(
        'RESEND_API_KEY is not configured.',
      );
    }

    const appointment = await req.json();

    const {
      first_name,
      last_name,
      email,
      phone,
      service,
      appointment_date,
      appointment_time,
      confirmation_number,
      status,
      message,
    } = appointment;

    if (
      !first_name ||
      !email ||
      !service ||
      !appointment_date ||
      !appointment_time ||
      !confirmation_number ||
      !status
    ) {
      return new Response(
        JSON.stringify({
          error:
            'Missing required appointment information.',
        }),
        {
          status: 400,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          },
        },
      );
    }

    if (
      status !== 'confirmed' &&
      status !== 'cancelled'
    ) {
      return new Response(
        JSON.stringify({
          error:
            'Invalid appointment status.',
        }),
        {
          status: 400,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          },
        },
      );
    }

    const safeFirstName =
      escapeHtml(first_name);

    const safeLastName =
      escapeHtml(last_name);

    const safeEmail =
      escapeHtml(email);

    const safePhone =
      escapeHtml(phone);

    const safeService =
      escapeHtml(service);

    const safeDate =
      escapeHtml(appointment_date);

    const safeTime =
      escapeHtml(appointment_time);

    const safeConfirmation =
      escapeHtml(confirmation_number);

    const safeMessage =
      escapeHtml(message);

    let subject;
    let heading;
    let statusMessage;
    let statusColor;

    if (status === 'confirmed') {
      subject =
        'Your Appointment Is Confirmed — Lashes by Mariia';

      heading =
        'Your Appointment Is Confirmed!';

      statusMessage =
        'Great news! Your appointment with Lashes by Mariia has been confirmed. We look forward to seeing you!';

      statusColor = '#2f7d4a';
    } else {
      subject =
        'Appointment Cancellation — Lashes by Mariia';

      heading =
        'Appointment Cancelled';

      statusMessage =
        'Your appointment with Lashes by Mariia has been cancelled. If you would like to schedule another appointment, please contact us.';

      statusColor = '#a94442';
    }

    const customerEmail = {
      from: FROM_EMAIL,
      to: [email],
      reply_to: ADMIN_EMAIL,
      subject,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 650px; margin: 0 auto; color: #333; line-height: 1.6;">
          <h1 style="margin-bottom: 5px;">
            Lashes by Mariia
          </h1>

          <p style="color: #777;">
            Appointment Update
          </p>

          <hr>

          <h2 style="color: ${statusColor};">
            ${heading}
          </h2>

          <p>
            Hi ${safeFirstName},
          </p>

          <p>
            ${statusMessage}
          </p>

          <h3>
            Appointment Details
          </h3>

          <p>
            <strong>Confirmation:</strong>
            ${safeConfirmation}
          </p>

          <p>
            <strong>Service:</strong>
            ${safeService}
          </p>

          <p>
            <strong>Date:</strong>
            ${safeDate}
          </p>

          <p>
            <strong>Time:</strong>
            ${safeTime}
          </p>

          ${
            status === 'confirmed'
              ? `
                <p style="margin-top: 25px;">
                  Please arrive on time for your appointment.
                  If you need to make any changes, contact us as soon as possible.
                </p>
              `
              : ''
          }

          ${
            status === 'cancelled'
              ? `
                <p style="margin-top: 25px;">
                  If you would like to book a new appointment,
                  please visit our website.
                </p>
              `
              : ''
          }

          <hr>

          <p>
            Thank you for choosing
            <strong>Lashes by Mariia</strong> 💕
          </p>

          <p>
            If you need to contact us, email
            <a href="mailto:${ADMIN_EMAIL}">
              ${ADMIN_EMAIL}
            </a>.
          </p>
        </div>
      `,
    };

    const adminEmail = {
      from: FROM_EMAIL,
      to: [ADMIN_EMAIL],
      reply_to: email,
      subject:
        status === 'confirmed'
          ? `Appointment Confirmed — ${first_name} ${last_name || ''}`
          : `Appointment Cancelled — ${first_name} ${last_name || ''}`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 650px; margin: 0 auto; color: #333; line-height: 1.6;">
          <h1>
            Lashes by Mariia
          </h1>

          <p>
            Appointment status updated.
          </p>

          <hr>

          <h2>
            ${
              status === 'confirmed'
                ? 'Confirmed'
                : 'Cancelled'
            }
          </h2>

          <h3>
            Appointment Details
          </h3>

          <p>
            <strong>Confirmation:</strong>
            ${safeConfirmation}
          </p>

          <p>
            <strong>Service:</strong>
            ${safeService}
          </p>

          <p>
            <strong>Date:</strong>
            ${safeDate}
          </p>

          <p>
            <strong>Time:</strong>
            ${safeTime}
          </p>

          <h3>
            Customer
          </h3>

          <p>
            <strong>Name:</strong>
            ${safeFirstName} ${safeLastName}
          </p>

          <p>
            <strong>Email:</strong>
            ${safeEmail}
          </p>

          <p>
            <strong>Phone:</strong>
            ${safePhone || 'Not provided'}
          </p>

          ${
            safeMessage
              ? `
                <h3>Customer Message</h3>
                <p>${safeMessage}</p>
              `
              : ''
          }
        </div>
      `,
    };

    const customerResponse = await fetch(
      'https://api.resend.com/emails',
      {
        method: 'POST',
        headers: {
          Authorization:
            `Bearer ${RESEND_API_KEY}`,
          'Content-Type':
            'application/json',
        },
        body: JSON.stringify(
          customerEmail,
        ),
      },
    );

    if (!customerResponse.ok) {
      const errorText =
        await customerResponse.text();

      throw new Error(
        `Resend customer email failed: ${errorText}`,
      );
    }

    const adminResponse = await fetch(
      'https://api.resend.com/emails',
      {
        method: 'POST',
        headers: {
          Authorization:
            `Bearer ${RESEND_API_KEY}`,
          'Content-Type':
            'application/json',
        },
        body: JSON.stringify(
          adminEmail,
        ),
      },
    );

    if (!adminResponse.ok) {
      const errorText =
        await adminResponse.text();

      throw new Error(
        `Resend admin email failed: ${errorText}`,
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        status,
        message:
          'Appointment status emails sent successfully.',
      }),
      {
        status: 200,
        headers: {
          'Content-Type':
            'application/json',
          'Access-Control-Allow-Origin':
            '*',
        },
      },
    );
  } catch (error) {
    console.error(error);

    return new Response(
      JSON.stringify({
        error:
          error instanceof Error
            ? error.message
            : 'Unable to send appointment status emails.',
      }),
      {
        status: 500,
        headers: {
          'Content-Type':
            'application/json',
          'Access-Control-Allow-Origin':
            '*',
        },
      },
    );
  }
});
