Medigo
Medigo is a Flutter app for booking lab tests at home and discovering nearby clinics. Users can browse tests, manage bookings, and view nearby clinics; technicians have a separate workflow for managing jobs.
Features
- Sign up, log in, and manage your profile
- Search and browse lab tests
- Find nearby clinics on a map
- Book tests and complete the payment flow
- View booking history
- Technician dashboard for jobs and earnings
Tech Stack
- Flutter / Dart with Provider for state management
- Firebase Authentication and Cloud Firestore
- Firebase Storage, Cloud Messaging, and Cloud Functions
- Flutter Map, Geolocator, and Geocoding
- Razorpay payment integration
Run Locally
1. Install Flutter and the required platform tools.
2. Clone the repository:git clone https://github.com/RiteshD2005/Medigo1.0.git
   cd Medigo1.0
3. Configure Firebase and any required payment/location settings for your environment.
4. Install dependencies and run the app:flutter pub get
   flutter run
Required Firebase and payment configuration must be set up before testing those integrations. Never commit private credentials or secret keys.
