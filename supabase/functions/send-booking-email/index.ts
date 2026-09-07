import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY');

const ADMIN_EMAIL = 'lashesmariia@gmail.com';

const FROM_EMAIL = 'Lashes by Mariia <appointments@lashesbymariia.com>';

serve(async (req) => {
  // Allow browser requests from your website
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers':
          'authorization, x-client-info, apikey, content-type',
      },
    });
  }

  try {
    if (!RESEND_API_KEY) {
      throw new Error('RESEND_API_KEY is not configured.');
    }

    const appointment = await req.json();

    const {
      firstName,
      lastName,
      email,
      phone,
      service,
      date,
      time,
      message,
      confirmationNumber,
    } = appointment;

    if (
      !firstName ||
      !email ||
      !service ||
      !date ||
      !time ||
      !confirmationNumber
    ) {
      return new Response(
        JSON.stringify({
          error: 'Missing required appointment information.',
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

    const adminEmail = {
      from: FROM_EMAIL,
      to: [ADMIN_EMAIL],
      reply_to: email,
      subject: `New Appointment Request — ${firstName} ${lastName || ''}`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 650px; margin: 0 auto; color: #333;">
          <h1 style="margin-bottom: 5px;">Lashes by Mariia</h1>
          <p style="color: #777;">New appointment request</p>

          <hr>

          <h2>Appointment Details</h2>

          <p><strong>Confirmation:</strong> ${confirmationNumber}</p>
          <p><strong>Service:</strong> ${service}</p>
          <p><strong>Date:</strong> ${date}</p>
          <p><strong>Time:</strong> ${time}</p>

          <h2>Customer</h2>

          <p><strong>Name:</strong> ${firstName} ${lastName || ''}</p>
          <p><strong>Email:</strong> ${email}</p>
          <p><strong>Phone:</strong> ${phone || 'Not provided'}</p>

          ${
            message
              ? `<h2>Message</h2><p>${message}</p>`
              : ''
          }

          <hr>

          <p>
            <strong>Status:</strong> Pending
          </p>

          <p>
            Log in to the Lashes by Mariia admin dashboard
            to confirm or cancel this appointment.
          </p>
        </div>
      `,
    };

    const customerEmail = {
      from: FROM_EMAIL,
      to: [email],
      reply_to: ADMIN_EMAIL,
      subject: `Appointment Request Received — Lashes by Mariia`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 650px; margin: 0 auto; color: #333;">
          <h1 style="margin-bottom: 5px;">Lashes by Mariia</h1>

          <p>Thank you for booking with us, ${firstName}!</p>

          <hr>

          <h2>Appointment Request</h2>

          <p>
            We've received your appointment request.
            Your appointment is currently <strong>pending confirmation</strong>.
          </p>

          <h3>Appointment Details</h3>

          <p><strong>Confirmation:</strong> ${confirmationNumber}</p>
          <p><strong>Service:</strong> ${service}</p>
          <p><strong>Date:</strong> ${date}</p>
          <p><strong>Time:</strong> ${time}</p>

          <p>
            We'll contact you once your appointment has been confirmed.
          </p>

          <hr>

          <p>
            Thank you for choosing <strong>Lashes by Mariia</strong> 💕
          </p>

          <p>
            If you need to contact us, email
            <a href="mailto:${ADMIN_EMAIL}">${ADMIN_EMAIL}</a>.
          </p>
        </div>
      `,
    };

    // Send the email to Mariia
    const adminResponse = await fetch(
      'https://api.resend.com/emails',
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${RESEND_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(adminEmail),
      },
    );

    if (!adminResponse.ok) {
      const errorText = await adminResponse.text();

      throw new Error(
        `Resend admin email failed: ${errorText}`,
      );
    }

    // Send confirmation to customer
    const customerResponse = await fetch(
      'https://api.resend.com/emails',
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${RESEND_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(customerEmail),
      },
    );

    if (!customerResponse.ok) {
      const errorText = await customerResponse.text();

      throw new Error(
        `Resend customer email failed: ${errorText}`,
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Appointment emails sent successfully.',
      }),
      {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
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
            : 'Unable to send appointment emails.',
      }),
      {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      },
    );
  }
});
