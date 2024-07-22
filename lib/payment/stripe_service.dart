import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:stripe_checkout/stripe_checkout.dart';

class StripeService {
  static String secretKey = "sk_test_51O2XKdGlgPEOIHgWFImo9s18gZOagARjRU1KkwoMFDt7pI8nqEmjWU2A4DNlk21r2Hek7FUhGAa1wrlQsh22IEL400mL1khbQR";
  static String publishableKey = "pk_test_51O2XKdGlgPEOIHgW6eN5sfccHhofpFRDDJrrRoCX3i6OtN5tnoJ9GeJ1A14FpqHOWHgveDZeTQjpzyZrrH65d8HH00xTDDZq0W";


  static Future<dynamic> createCheckoutSession(
      List<dynamic> productItems,
      totalAmount,
      ) async {
    final url = Uri.parse("https://api.stripe.com/v1/checkout/sessions");


    String lineItems = "";
    int index = 0;

    productItems.forEach(
          (val) {
        var productPrice = (val["productPrice"] * 100).round().toString();
        lineItems +=
        "&line_items[$index][price_data][product_data][name]=${val['productName']}";
        lineItems +=
        "&line_items[$index][price_data][unit_amount]=$productPrice";
        lineItems +=
        "&line_items[$index][price_data][currency]=GBP";
        lineItems +=
        "&line_items[$index][quantity]=${val['qty'].toString()}";


        index++;


      },
    );

    final response = await http.post(
      url,
      body: 'success_url=https://checkout.stripe.dev/success&mode=payment$lineItems',
      headers: {
        'Authorization': 'Bearer $secretKey',
        'Content-Type': 'application/x-www-form-urlencoded'

      },
    );

    return json.decode(response.body)["id"];

  }


  static Future<dynamic> stripePaymentCheckout(
      productItems,
      subTotal,
      context,
      mounted,  {
        onSuccess,
        onCancel,
        onError,
      }) async {
    final String sessionId = await createCheckoutSession(
      productItems,
      subTotal,
    );



    final result = await redirectToCheckout(
      context: context,
      sessionId: sessionId,
      publishableKey: publishableKey,
      successUrl: "https://checkout.stripe.dev/success",
      canceledUrl: "https://checkout.stripe.dev/cancel",
    );


    if (mounted) {
      final text = result.when(
        redirected: () => 'Redirected Successfully',
        success: () => onSuccess(),
        canceled: () => onCancel(),
        error: (e) => onError(e),
      );

      return text;


    }

  }


  static Future<dynamic> splitPayment(
      double totalAmount, String bankAccountNumber) async {
    // Calculate 10% for the bank account
    double bankAmount = (totalAmount * 0.10);

    // Calculate 90% for Stripe
    double stripeAmount = (totalAmount * 0.90);

    // Implement the logic to transfer the amounts to the bank and Stripe
    // This could involve calling external APIs or services
    // For simplicity, this function is just returning a success message
    return 'Split payment completed - Bank Amount: $bankAmount, Stripe Amount: $stripeAmount';
  }


}