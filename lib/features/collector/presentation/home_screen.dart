import 'package:flutter/material.dart';
import 'package:smart_isp/features/collector/map_screen.dart';
import 'package:smart_isp/features/profile/presentation/profile_page.dart';
import 'package:smart_isp/features/clients/presentation/screens/client_details.dart';

class CollectorHomePage extends StatefulWidget {
  const CollectorHomePage({super.key});

  @override
  State<CollectorHomePage> createState() => _CollectorHomePageState();
}

class _CollectorHomePageState extends State<CollectorHomePage> {
  String selectedStatus = "All";
  String searchQuery = "";
  int _currentIndex = 0;

  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> clients = [
    {"name": "Juan Dela Cruz", "status": "Active", "distance": "200m"},
    {"name": "Maria Santos", "status": "Inactive", "distance": "500m"},
    {"name": "Pedro Gomez", "status": "Inactive", "distance": "1.2km"},
    {"name": "Andres Bonifacio", "status": "Active", "distance": "1.5km"},
    {"name": "Emilio Jacinto", "status": "Active", "distance": "3.7km"},
    {"name": "Diana Cortez", "status": "Inactive", "distance": "1.2km"},
  ];

  Future<void> _refreshClients() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      searchQuery = "";
      selectedStatus = "All";
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredClients = clients.where((c) {
      final matchesStatus =
          selectedStatus == "All" || c["status"] == selectedStatus;
      final matchesSearch =
      c["name"].toLowerCase().contains(searchQuery.toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,

      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            decoration: const BoxDecoration(
              color: Colors.blue,
              //borderRadius: BorderRadius.only(
               // bottomLeft: Radius.circular(20),
                //bottomRight: Radius.circular(20),
              //),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              spreadRadius: 1,
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },
                          textAlignVertical: TextAlignVertical.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Poppins',
                          ),
                          decoration: InputDecoration(
                            hintText: "Search",
                            prefixIcon: const Icon(Icons.search, size: 20),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      flex: 0,
                      child: SizedBox(
                        height: 40,
                        child: _buildDropdown(
                          "Status",
                          ["All", "Active", "Inactive"],
                          selectedStatus,
                              (val) {
                            setState(() => selectedStatus = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                Container(
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: const [
                      Text(
                        "Paid: 0",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "Unpaid: 0",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: RefreshIndicator(
              color: Colors.blue,
              onRefresh: _refreshClients,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: filteredClients.length,
                itemBuilder: (context, index) {
                  final client = filteredClients[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ClientDetails(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    client["name"],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: const [
                                      Icon(
                                        Icons.sim_card_rounded,
                                        size: 16,
                                        color: Colors.black54,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        "DITO: 09*******76",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        client["status"] == "Active"
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        size: 16,
                                        color: client["status"] == "Active"
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Status: ${client["status"]}",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: client["status"] == "Active"
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${client["distance"]} Away",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 18,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          switch (index) {
            case 0:
              break;
            case 1:
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const Profile(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
              break;
            case 2:
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const MapScreen(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_sharp),
            label: "Subscriptions",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: "Map",
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
      String hint,
      List<String> items,
      String value,
      Function(String) onSelected,
      ) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Center(
                child: Text(
                  hint,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: items.asMap().entries.map((entry) {
                  int index = entry.key;
                  String item = entry.value;
                  
                  return Column(
                    children: [
                      ListTile(
                        title: Text(
                          item,
                          style: const TextStyle(fontFamily: 'Poppins'),
                        ),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          setState(() {
                            onSelected(item);
                          });
                        },
                      ),
                      if (index < items.length - 1)
                        const Divider(
                          height: 1,
                          thickness: 0.5,
                          color: Colors.grey,
                        ),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        );
      },
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade400, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              value.isEmpty ? hint : value,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
                color: Colors.black87,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: Colors.black54,
            ),
          ],
        ),
      ),
    );
  }
}