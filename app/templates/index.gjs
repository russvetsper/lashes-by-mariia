import BookingForm from '../components/booking-form';

const services = [
  {
    name: 'Lash Lift & Lash Lamination',
    price: '$45',
    time: '45 min',
    description:
      'Professional lash lift and eyelash lamination in Brooklyn designed to lift, curl and define your natural lashes without eyelash extensions.',
  },
];

<template>
  <div class="site">

    {{!-- NAVIGATION --}}
    <header class="navbar">
      <div class="nav-container">

        <a href="#home" class="brand">
          <img
            src="/assets/images/lashes-logo.png"
            alt="Lashes by Mariia lash salon in Brooklyn NY"
          />
        </a>

        <nav class="desktop-nav">
          <a href="#home">Home</a>
          <a href="#services">Services</a>
          <a href="#work">Our Work</a>
          <a href="#about">About</a>
          <a href="#contact">Contact</a>

          <a
            href="#booking"
            class="nav-button"
          >
            Book Appointment
          </a>
        </nav>

        <a
          href="#booking"
          class="mobile-book-button"
        >
          Book
        </a>

      </div>
    </header>


    <main>

      {{!-- HERO --}}
      <section
        class="hero"
        id="home"
      >
        <div class="hero-content">

          <div class="hero-copy">

            <p class="eyebrow">
              PRIVATE LASH STUDIO · BROOKLYN, NY
            </p>

            <h1>
              Lash Lift & Lamination
              <span>in Brooklyn.</span>
            </h1>

            <p class="hero-description">
              Professional lash lift and lash lamination in Brooklyn,
              near Bensonhurst and 86th Street. Enhance your natural
              lashes with a beautifully lifted, curled and defined look
              without eyelash extensions.
            </p>

            <div class="hero-buttons">

              <a
                href="#booking"
                class="button button-primary"
              >
                Book Your Appointment
              </a>

              <a
                href="#services"
                class="button button-secondary"
              >
                Explore Services
              </a>

            </div>

            <div class="appointment-note">
              <span>✦</span>
              By appointment only
              <span>✦</span>
            </div>

          </div>


          <div class="hero-logo">

            <div class="hero-logo-frame">
              <img
                src="/assets/images/lashes-logo.png"
                alt="Lashes by Mariia eyelash salon Brooklyn"
              />
            </div>

          </div>

        </div>
      </section>


      {{!-- INTRO --}}
      <section class="intro-section">

        <div class="intro-content">

          <div class="decorative-line"></div>

          <p>
            Beautiful natural lashes with a professional lash lift
            and lamination in Brooklyn, New York.
          </p>

          <div class="decorative-line"></div>

        </div>

      </section>


      {{!-- SERVICES --}}
      <section
        class="services-section"
        id="services"
      >

        <div class="section-header">

          <p class="eyebrow">
            LASH SERVICES IN BROOKLYN
          </p>

          <h2>
            Professional Lash Lift & Lash Lamination
          </h2>

          <p>
            Looking for a lash lift or eyelash lamination in Brooklyn?
            Our professional lash treatment lifts, curls and defines
            your natural lashes for a polished, natural-looking result.
          </p>

        </div>


        <div class="services-grid">

          {{#each services as |service|}}

            <article class="service-card">

              <div class="service-top">

                <span class="service-number">
                  ✦
                </span>

                <span class="service-time">
                  {{service.time}}
                </span>

              </div>


              <div class="service-icon">
                ♡
              </div>


              <h3>
                {{service.name}}
              </h3>


              <p>
                {{service.description}}
              </p>


              <div class="service-bottom">

                <strong>
                  {{service.price}}
                </strong>

                <a href="#booking">
                  Book →
                </a>

              </div>

            </article>

          {{/each}}

        </div>


        {{!-- LASHES BY MARIIA BANNER --}}
        <div
          style="
            width: min(900px, 100%);
            margin: 75px auto 0;
            overflow: hidden;
            box-shadow: 0 20px 60px rgba(35, 25, 20, 0.08);
            background: #f8f4ef;
          "
        >
          <img
            src="/assets/images/lashes-by-mariia-banner.png"
            alt="Lashes by Mariia lash lift and lash lamination salon in Brooklyn NY"
            style="
              width: 100%;
              height: auto;
              display: block;
            "
          />
        </div>

      </section>


      {{!-- ABOUT --}}
      <section
        class="about-section"
        id="about"
      >

        <div class="about-image">

          <div class="about-image-background">
            <img
              src="/assets/images/lashes-logo.png"
              alt="Lashes by Mariia Brooklyn lash studio"
            />
          </div>

        </div>


        <div class="about-content">

          <p class="eyebrow">
            ABOUT LASHES BY MARIIA
          </p>

          <h2>
            Your Brooklyn
            <span>lash studio.</span>
          </h2>

          <p>
            Welcome to Lashes by Mariia — a private home-based
            eyelash salon in Brooklyn, New York, specializing in
            professional lash lift and lash lamination.
          </p>

          <p>
            Conveniently located near Bensonhurst and 86th Street,
            Lashes by Mariia offers personalized appointments for
            clients looking for beautifully lifted, curled and
            defined natural lashes.
          </p>

          <p>
            Every appointment is focused on you. From discussing
            your desired results to creating a natural lash look
            that complements your eyes, every detail matters.
          </p>

          <div class="signature">
            Mariia
          </div>

          <a
            href="#booking"
            class="button button-dark"
          >
            Book With Mariia
          </a>

        </div>

      </section>


      {{!-- EXPERIENCE --}}
      <section class="experience-section">

        <div class="section-header">

          <p class="eyebrow">
            THE EXPERIENCE
          </p>

          <h2>
            Professional natural lash care
          </h2>

        </div>


        <div class="experience-grid">

          <div class="experience-card">

            <div class="experience-icon">
              ✦
            </div>

            <h3>
              Customized
            </h3>

            <p>
              Your lash lift and lamination treatment is tailored
              to your natural lashes and the look you want to achieve.
            </p>

          </div>


          <div class="experience-card">

            <div class="experience-icon">
              ♡
            </div>

            <h3>
              Comfortable
            </h3>

            <p>
              Relax in a private, peaceful Brooklyn lash studio
              while your natural lashes are being transformed.
            </p>

          </div>


          <div class="experience-card">

            <div class="experience-icon">
              ✧
            </div>

            <h3>
              Professional
            </h3>

            <p>
              Professional products and careful attention to detail
              are used throughout every lash lift and lamination treatment.
            </p>

          </div>


          <div class="experience-card">

            <div class="experience-icon">
              ❋
            </div>

            <h3>
              Personal
            </h3>

            <p>
              Your appointment is your time —
              no crowded salon and no distractions.
            </p>

          </div>

        </div>

      </section>


      {{!-- OUR WORK --}}
      <section
        class="portfolio-section"
        id="work"
      >

        <div class="section-header">

          <p class="eyebrow">
            OUR LASH WORK
          </p>

          <h2>
            Beautiful results,
            <span class="section-script">
              naturally yours.
            </span>
          </h2>

          <p>
            See examples of professional lash lift and lash
            lamination results by Lashes by Mariia in Brooklyn.
            Each treatment is designed to enhance natural lashes
            with a lifted, curled and defined appearance.
          </p>

        </div>


        <div class="portfolio-grid">

          <figure class="portfolio-card">

            <img
              src="/assets/images/lash-work-1.jpg"
              alt="Lash lift and lash lamination result in Brooklyn by Lashes by Mariia"
              loading="lazy"
            />

            <figcaption>

              <span>
                Lash Lift & Lamination
              </span>

              <strong>
                Lashes by Mariia
              </strong>

            </figcaption>

          </figure>


          <figure class="portfolio-card">

            <img
              src="/assets/images/lash-work-2.jpg"
              alt="Natural eyelash lift result at Lashes by Mariia Brooklyn"
              loading="lazy"
            />

            <figcaption>

              <span>
                Natural Lash Treatment
              </span>

              <strong>
                Lashes by Mariia
              </strong>

            </figcaption>

          </figure>

        </div>

      </section>


      {{!-- PROFESSIONAL PRODUCTS --}}
      <section class="products-section">

        <div class="products-wrapper">

          <div class="products-copy">

            <p class="eyebrow">
              PROFESSIONAL LASH PRODUCTS
            </p>

            <h2>
              Quality products.
              <span>
                Beautiful results.
              </span>
            </h2>

            <p>
              Professional lash products are carefully selected
              to provide beautiful, consistent and high-quality
              lash lift and lamination results.
            </p>

            <p>
              Mariia uses professional Elleebana and Elleeplex
              Profusion products for lash lift and eyelash
              lamination treatments.
            </p>

            <a
              href="#booking"
              class="button button-dark"
            >
              Book Your Appointment
            </a>

          </div>


          <div class="products-gallery">

            <div class="product-photo product-photo-large">

              <img
                src="/assets/images/elleebana-products-1.jpg"
                alt="Elleebana professional lash lift products used by Lashes by Mariia"
                loading="lazy"
              />

            </div>


            <div class="product-photo">

              <img
                src="/assets/images/elleebana-products-2.jpg"
                alt="Elleeplex Profusion eyelash lamination products Brooklyn lash salon"
                loading="lazy"
              />

            </div>

          </div>

        </div>

      </section>


      {{!-- CERTIFICATION --}}
      <section
        class="certification-section"
        id="certification"
      >

        <div class="certification-wrapper">

          <div class="certificate-image-wrap">

            <a
              href="/assets/images/eyelash-lamination-certificate.png"
              target="_blank"
              rel="noopener noreferrer"
              class="certificate-link"
              aria-label="View Mariia's eyelash lamination certificate"
            >

              <img
                src="/assets/images/eyelash-lamination-certificate.png"
                alt="Professional eyelash lamination training certificate for Mariia Panteliuk"
                loading="lazy"
              />

              <span class="certificate-view">
                View Certificate ↗
              </span>

            </a>

          </div>


          <div class="certification-copy">

            <p class="eyebrow">
              TRAINING & CERTIFICATION
            </p>

            <h2>
              Professionally
              <span>
                trained.
              </span>
            </h2>

            <p>
              Mariia completed professional training in eyelash
              lamination through Royal Secrets Beauty Studio,
              providing professional lash lift and lamination
              services to clients in Brooklyn.
            </p>


            <div class="certification-details">

              <div>

                <span>
                  Training
                </span>

                <strong>
                  Eyelash Lamination
                </strong>

              </div>


              <div>

                <span>
                  Completed
                </span>

                <strong>
                  March 13, 2024
                </strong>

              </div>

            </div>


            <a
              href="#booking"
              class="button button-primary"
            >
              Book With Mariia
            </a>

          </div>

        </div>

      </section>


      {{!-- BOOKING --}}
      <section
        class="booking-section"
        id="booking"
      >

        <div class="booking-wrapper">

          <div class="booking-intro">

            <p class="eyebrow">
              BOOK A LASH APPOINTMENT IN BROOKLYN
            </p>

            <h2>
              Ready for your
              <span>
                perfect lashes?
              </span>
            </h2>

            <p>
              Book your lash lift and lash lamination appointment
              in Brooklyn near Bensonhurst and 86th Street.
              Choose your appointment date and time and submit
              your booking request. You'll receive confirmation
              once your appointment is approved.
            </p>


            <div class="booking-details">

              <div>

                <span>
                  Service
                </span>

                <strong>
                  Lash Lift & Lash Lamination
                </strong>

              </div>


              <div>

                <span>
                  Treatment Time
                </span>

                <strong>
                  45 Minutes
                </strong>

              </div>


              <div>

                <span>
                  Price
                </span>

                <strong>
                  $45
                </strong>

              </div>


              <div>

                <span>
                  Location
                </span>

                <strong>
                  Brooklyn, NY
                </strong>

              </div>


              <div>

                <span>
                  Nearby
                </span>

                <strong>
                  Bensonhurst · 86th Street
                </strong>

              </div>


              <div>

                <span>
                  Appointments
                </span>

                <strong>
                  By appointment only
                </strong>

              </div>


              <div>

                <span>
                  Instagram
                </span>

                <strong>
                  @lashes.by.maria.nyc
                </strong>

              </div>

            </div>

          </div>


          <BookingForm
            @services={{services}}
          />

        </div>

      </section>


      {{!-- CONTACT --}}
      <section
        class="contact-section"
        id="contact"
      >

        <div class="contact-content">

          <p class="eyebrow">
            BROOKLYN LASH STUDIO
          </p>

          <h2>
            Let's talk lashes.
          </h2>

          <p>
            Looking for a lash lift, lash lamination or natural
            eyelash lift in Brooklyn? Lashes by Mariia is located
            near Bensonhurst and 86th Street. Contact us with
            questions about the treatment, your appointment
            or aftercare.
          </p>


          <div class="contact-links">

            {{!-- EMAIL --}}
            <a href="mailto:lashesmariia@gmail.com">

              <span>
                Email
              </span>

              <strong>
                lashesmariia@gmail.com
              </strong>

            </a>


            {{!-- INSTAGRAM --}}
            <a
              href="https://www.instagram.com/lashes.by.maria.nyc"
              target="_blank"
              rel="noopener noreferrer"
            >

              <span>
                Instagram
              </span>

              <strong>
                @lashes.by.maria.nyc
              </strong>

            </a>


            {{!-- FACEBOOK --}}
            <a
              href="https://www.facebook.com/LahesByMariia"
              target="_blank"
              rel="noopener noreferrer"
            >

              <span>
                Facebook
              </span>

              <strong>
                Lashes by Mariia
              </strong>

            </a>

          </div>

        </div>

      </section>

    </main>


    {{!-- FOOTER --}}
    <footer class="footer">

      <div class="footer-content">

        <a
          href="#home"
          class="footer-brand"
        >

          <img
            src="/assets/images/lashes-logo.png"
            alt="Lashes by Mariia lash lift and lamination Brooklyn NY"
          />

        </a>


        <p>
          © 2026 Lashes by Mariia
        </p>


        <a
          href="#home"
          class="back-top"
        >
          Back to top ↑
        </a>


        <a
          href="/admin"
          class="admin-secret-link"
          aria-label="Admin login"
        >
          Admin
        </a>

      </div>

    </footer>

  </div>
</template>
