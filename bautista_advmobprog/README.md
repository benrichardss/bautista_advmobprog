# bautista_advmobprog

Lab Activity 4: The User model represents the authenticated user data returned by the API. UserService handles login and saves the user information in SharedPreferences. After login, the saved data is converted back into a User object and passed to HomeScreen, which sends it to ProfileScreen for rendering. This updated Model–Service–Screen pattern keeps data handling, storage, and UI responsibilities separate.

The saved user ID is passed from HomeScreen to CartScreen. CartScreen sends the ID to CartProvider, which calls CartService.getCartByUserId() using the /carts/user/{userId} endpoint. The returned cart products are stored in the provider and rendered by the screen, including their quantities, prices, discounts, and totals.
