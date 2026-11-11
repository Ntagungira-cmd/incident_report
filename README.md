# Campus incident reports

Students report problems on campus. Staff claim a report when they start work on it, and an admin can assign an unclaimed report to a staff member. Everyone can see the status move from Submitted to In Progress to Resolved.

## How it works

Sign-in is email and password through Firebase Auth. A profile in Firestore stores the person's name, department, location, and role.

- **Student.** Files a report and sees only their own. Registration always creates a student.
- **Staff.** Sees every report, changes status, and claims an unclaimed report. Claiming a submitted report moves it to In Progress.
- **Admin.** Does everything staff can do, and can assign an unclaimed report to a staff member. Admins are not created from the register page.

A report has a title, category, location, description, and an optional photo. Photos upload to Cloudinary with an unsigned preset, so the API secret stays out of the app. Profile photos use the same Cloudinary preset as report photos. The person working on a report is stored on the report. In Progress with nobody on it shows as Unassigned.

Staff and admin accounts are created by the seed script, not by registering in the app.

## Run the app

Install Flutter, then from this directory:

```bash
flutter pub get
```

Photo upload needs a Cloudinary cloud name and an unsigned upload preset whose folder is `reports`. Put them in `keys/cloudinary.json` (that folder is gitignored):

```json
{
  "CLOUDINARY_CLOUD_NAME": "your_cloud_name",
  "CLOUDINARY_UPLOAD_PRESET": "your_preset_name"
}
```

Run:

```bash
flutter run --dart-define-from-file=keys/cloudinary.json
```

In Android Studio, open **Run → Edit Configurations**, select the Flutter configuration, and set **Additional run args** to:

```text
--dart-define-from-file=keys/cloudinary.json
```

Stop the app and run it again after changing that file. Hot reload does not pick up new values. Reports without a photo still submit if the file is missing.

## Seed accounts and rules

The seed script writes three accounts and six sample reports into the `incident-report-5a32a` project. From `tool/`:

```bash
npm install
```

Then, from the repo root, with a Firebase service account JSON:

```bash
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
node tool/seed.mjs
```

| Email | Password | Role |
| --- | --- | --- |
| amina.hassan@campus.edu | campus123 | student |
| jean.habimana@campus.edu | campus123 | staff |
| admin@campus.edu | campus123 | admin |

Deploy the Firestore rules so claim and assign are allowed:

```bash
firebase deploy --only firestore:rules
```

## Tests

```bash
flutter test
```
