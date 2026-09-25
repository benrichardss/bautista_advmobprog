# bautista_advmobprog

Lab Activity 5: The app starts by checking the saved login type and session. Sign-in can use either DummyJSON, which sends a username and password to its login API, or Firebase, which authenticates with email and password. Sign-up is Firebase-only: it creates an account, sets the username, stores profile details locally, and opens Home. UserService brings both options behind one interface, handling authentication, login-type tracking, and saving user data for the rest of the app.

Firebase adds real account creation, persistent sign-in, and account-management features such as password changes and account deletion, giving the lab experience with a managed authentication service alongside a REST API. The extra sign-up details, such as age and contact number, are currently stored only on the device in SharedPreferences; they are not synced to a cloud database.
