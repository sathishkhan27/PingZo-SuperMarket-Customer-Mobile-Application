import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/address_model.dart';
import '../../services/location_provider.dart';
import '../../services/cart_provider.dart';

class LocationMapPickerScreen extends StatefulWidget {
  final String customerId;
  const LocationMapPickerScreen({Key? key, this.customerId = '1'}) : super(key: key);

  @override
  State<LocationMapPickerScreen> createState() => _LocationMapPickerScreenState();
}

class _LocationMapPickerScreenState extends State<LocationMapPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LocationProvider>(context, listen: false).loadLocationData(customerId: widget.customerId);
    });
  }

  List<AddressModel> _getFilteredAddresses(List<AddressModel> allAddresses) {
    if (_searchQuery.trim().isEmpty) return allAddresses;
    final q = _searchQuery.toLowerCase();
    return allAddresses.where((a) {
      return a.type.toLowerCase().contains(q) || a.addressDetails.toLowerCase().contains(q);
    }).toList();
  }

  IconData _getIconForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('home')) return Icons.home_outlined;
    if (t.contains('work') || t.contains('office')) return Icons.apartment_rounded;
    return Icons.location_on_outlined;
  }

  void _selectAddress(AddressModel address) {
    final locProvider = Provider.of<LocationProvider>(context, listen: false);
    locProvider.setActiveAddress(address);

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.setLocation("${address.type} - ${address.addressDetails}");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Selected Location: ${address.type}"),
        backgroundColor: const Color(0xFFC2185B),
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.pop(context, address.addressDetails);
  }

  Future<void> _useCurrentLocation() async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text("Detecting current GPS location..."),
          ],
        ),
        backgroundColor: Color(0xFFC2185B),
        duration: Duration(seconds: 2),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;
    final locProvider = Provider.of<LocationProvider>(context, listen: false);

    final detectedAddr = await locProvider.saveCurrentGpsLocation(
      addressDetails: "36, Vijaya Raghava Rd, Sudhama Commercial Bldg, T. Nagar, Chennai, 600017",
      customerId: widget.customerId,
    );

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.setLocation("${detectedAddr.type} - ${detectedAddr.addressDetails}");

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Text("Location set to Current Location! 🎯"),
        backgroundColor: Color(0xFF25D366),
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.pop(context, detectedAddr.addressDetails);
  }

  void _requestAddressFromFriend() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.share_outlined, size: 40, color: Color(0xFF25D366)),
              const SizedBox(height: 12),
              const Text(
                "Request Address From Friend",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Share a link via WhatsApp or Message to allow your friend to input their exact delivery location.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  label: const Text("Share Request Link", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openAddEditAddressSheet({AddressModel? addressToEdit}) {
    final isEditing = addressToEdit != null;
    String selectedType = addressToEdit?.type ?? "Home";
    final houseNoCtrl = TextEditingController(
      text: isEditing ? addressToEdit.addressDetails.split(',').first : "",
    );
    final streetCtrl = TextEditingController(
      text: isEditing ? addressToEdit.addressDetails : "",
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isEditing ? "Edit Address" : "Add New Address",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "SAVE ADDRESS AS",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: ["Home", "Work", "Other"].map((tag) {
                      final isSel = selectedType.toLowerCase() == tag.toLowerCase();
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedType = tag),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFFC2185B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isSel ? Colors.white : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: houseNoCtrl,
                    decoration: InputDecoration(
                      labelText: "House / Flat / Building No.",
                      labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: streetCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: "Full Address / Street / Landmark",
                      labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (streetCtrl.text.trim().isEmpty) return;
                        Navigator.pop(ctx);

                        final locProvider = Provider.of<LocationProvider>(context, listen: false);

                        final targetAddr = AddressModel(
                          id: isEditing ? addressToEdit.id : '',
                          customerId: widget.customerId,
                          type: selectedType,
                          distance: isEditing ? addressToEdit.distance : "0 m",
                          addressDetails: streetCtrl.text.trim(),
                          isDefault: isEditing ? addressToEdit.isDefault : false,
                        );

                        if (isEditing) {
                          await locProvider.editAddress(targetAddr, customerId: widget.customerId);
                        } else {
                          await locProvider.saveAddress(targetAddr, customerId: widget.customerId);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC2185B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        isEditing ? "Update Address" : "Save & Use Address",
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddressOptionsMenu(AddressModel address) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: Color(0xFFC2185B)),
                title: const Text("Edit Address", style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  _openAddEditAddressSheet(addressToEdit: address);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined, color: Color(0xFF0F172A)),
                title: const Text("Share Address", style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Address copied: ${address.addressDetails}")),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text("Delete Address", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final locProvider = Provider.of<LocationProvider>(context, listen: false);
                  await locProvider.deleteAddress(address.id, customerId: widget.customerId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDottedDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.maxWidth;
        const dashWidth = 4.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFCBD5E1)),
              ),
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top Custom Navigation Row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: Color(0xFF0F172A),
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Select Location",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 22),
                    hintText: "Search Address",
                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 15, fontWeight: FontWeight.w500),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Scrollable Content
            Expanded(
              child: Consumer<LocationProvider>(
                builder: (context, locProvider, _) {
                  if (locProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFFC2185B)));
                  }

                  final filteredAddresses = _getFilteredAddresses(locProvider.addresses);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Action Box 1: Use Current Location & Add New Address
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                          ),
                          child: Column(
                            children: [
                              // Use my Current Location
                              InkWell(
                                onTap: _useCurrentLocation,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  child: Row(
                                    children: const [
                                      Icon(Icons.gps_fixed_rounded, color: Color(0xFFC2185B), size: 20),
                                      SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          "Use my Current Location",
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFFC2185B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 16, endIndent: 16),

                              // Add New Address
                              InkWell(
                                onTap: () => _openAddEditAddressSheet(),
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  child: Row(
                                    children: const [
                                      Icon(Icons.add_rounded, color: Color(0xFFC2185B), size: 22),
                                      SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          "Add New Address",
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFFC2185B),
                                          ),
                                        ),
                                      ),
                                      Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 22),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Action Box 2: Request Address from Friend
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                          ),
                          child: InkWell(
                            onTap: _requestAddressFromFriend,
                            borderRadius: BorderRadius.circular(18),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              child: Row(
                                children: const [
                                  Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366), size: 22),
                                  SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      "Request address from friend",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 22),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Saved Addresses Section Header
                        const Text(
                          "Saved Addresses",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Saved Addresses Card List
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                          ),
                          child: filteredAddresses.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(30.0),
                                  child: Center(
                                    child: Text(
                                      "No saved addresses found",
                                      style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filteredAddresses.length,
                                  separatorBuilder: (ctx, idx) => Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: _buildDottedDivider(),
                                  ),
                                  itemBuilder: (ctx, idx) {
                                    final addr = filteredAddresses[idx];
                                    final isSelected = locProvider.activeAddress?.id == addr.id;

                                    return InkWell(
                                      onTap: () => _selectAddress(addr),
                                      borderRadius: BorderRadius.vertical(
                                        top: idx == 0 ? const Radius.circular(20) : Radius.zero,
                                        bottom: idx == filteredAddresses.length - 1 ? const Radius.circular(20) : Radius.zero,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Icon(_getIconForType(addr.type), color: isSelected ? const Color(0xFFC2185B) : const Color(0xFF334155), size: 24),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        addr.type,
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w800,
                                                          color: isSelected ? const Color(0xFFC2185B) : const Color(0xFF0F172A),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        "• ${addr.distance}",
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w700,
                                                          color: Color(0xFF64748B),
                                                        ),
                                                      ),
                                                      if (isSelected) ...[
                                                        const SizedBox(width: 8),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFFCE4EC),
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: const Text(
                                                            "SELECTED",
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.w900,
                                                              color: Color(0xFFC2185B),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    addr.addressDetails,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w500,
                                                      color: Color(0xFF475569),
                                                      height: 1.3,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            IconButton(
                                              icon: const Icon(Icons.share_outlined, color: Color(0xFF94A3B8), size: 20),
                                              onPressed: () {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text("Sharing address: ${addr.addressDetails}")),
                                                );
                                              },
                                              constraints: const BoxConstraints(),
                                              padding: const EdgeInsets.all(6),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF94A3B8), size: 20),
                                              onPressed: () => _showAddressOptionsMenu(addr),
                                              constraints: const BoxConstraints(),
                                              padding: const EdgeInsets.all(6),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
