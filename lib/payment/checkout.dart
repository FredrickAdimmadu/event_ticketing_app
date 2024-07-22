import 'package:flutter/material.dart';
import 'stripe_service.dart'; // Make sure this import points to your StripeService file

class CheckoutPage extends StatefulWidget {
  final String productName;
  final double productPrice;
  final int qty;

  const CheckoutPage({
    Key? key,
    required this.productName,
    required this.productPrice,
    required this.qty,
  }) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  @override
  Widget build(BuildContext context) {
    final items = [
      {
        "productPrice": widget.productPrice,
        "productName": widget.productName,
        "qty": widget.qty,
      },
    ];

    final totalAmount = widget.productPrice * widget.qty; // Calculate total amount dynamically

    return Scaffold(
      appBar: AppBar(
        title: Text("Stripe Checkout"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Product: ${widget.productName}'),
            Text('Price: \$${widget.productPrice}'),
            Text('Quantity: ${widget.qty}'),
            Text('Total: \$${totalAmount}'),
            SizedBox(height: 20),
            TextButton(
              onPressed: () async {
                StripeService.stripePaymentCheckout(
                  items,
                  totalAmount, // Use dynamic total amount
                  context,
                  mounted,
                  onSuccess: () {
                    print("SUCCESS");
                  },
                  onCancel: () {
                    print("Cancel");
                  },
                  onError: (e) {
                    print("Error: " + e.toString());
                  },
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: Text("Checkout"),
            ),
          ],
        ),
      ),
    );
  }
}
