import 'package:flutter/material.dart';

class Payment extends StatelessWidget {
  const Payment({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: true,
        backgroundColor: Colors.lightBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: Padding(
        padding: const EdgeInsets.only(top: 32.0, left: 16.0, right: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                print("Card tapped!");
              },
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(width: 0, color: Colors.black12),
                ),
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name Row
                      Row(
                        children: const [
                          Icon(Icons.person, size: 28, color: Colors.black87),
                          SizedBox(width: 12),
                          Text(
                            'John Doe',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

                      // Phone Row
                      Row(
                        children: const [
                          Icon(Icons.phone, size: 18, color: Colors.black87),
                          SizedBox(width: 8),
                          Text("Phone Number: 09******69"),
                        ],
                      ),
                      SizedBox(height: 8),

                      // Plan Amount Row
                      Row(
                        children: const [
                          Icon(Icons.article, size: 18, color: Colors.black87),
                          SizedBox(width: 8),
                          Text("Plan Amount: ₱599.00"),
                        ],
                      ),
                      SizedBox(height: 8),

                      // Status Row
                      Row(
                        children: const [
                          Icon(Icons.article, size: 18, color: Colors.black87),
                          SizedBox(width: 8),
                          Text('Status:'),
                          Text(" Unpaid", style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "Select month to pay",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(value: "Jan", child: Text("January")),
                DropdownMenuItem(value: "Feb", child: Text("February")),
                DropdownMenuItem(value: "Mar", child: Text("March")),
              ],
              onChanged: (value) {
                print("Selected: $value");
              },
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                print("Submit Payment tapped!");
              },
              icon: const Icon(Icons.payments, color: Colors.white),
              label: const Text(
                "Submit Payment",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 252, 252, 252),
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 36,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                print("Submit Payment tapped!");
              },
              icon: const Icon(Icons.print, color: Colors.lightBlue),
              label: const Text(
                "Print Receipt",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
