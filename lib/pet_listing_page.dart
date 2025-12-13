import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'add_pet_page.dart';
import 'my_pets_page.dart';
import 'adoption_request_dialog.dart';
import 'pet_requests_page.dart';

class PetListingPage extends StatefulWidget {
  const PetListingPage({super.key});

  @override
  _PetListingPageState createState() => _PetListingPageState();
}

class _PetListingPageState extends State<PetListingPage> {
  List<dynamic> _pets = [];
  bool _isLoading = true;
  String _selectedTab = 'all-pets';
  int? _currentUserId;
  final Map<String, List<dynamic>> _cachedData = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadPets();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await ApiService.getCurrentUser();
      setState(() {
        _currentUserId = user['id'];
      });
    } catch (e) {
      print('❌ Error loading current user: $e');
    }
  }

  Future<void> _loadPets({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedData.containsKey(_selectedTab)) {
      setState(() {
        _pets = _cachedData[_selectedTab]!;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<dynamic> pets;
      if (_selectedTab == 'all-pets') {
        pets = await ApiService.getPetListings();
      } else if (_selectedTab == 'history') {
        pets = await ApiService.getMyAdoptionHistory();
      } else if (_selectedTab == 'my-pets') {
        pets = await ApiService.getMyPets();
      } else if (_selectedTab == 'my-requests') {
        pets = await ApiService.getMyAdoptionRequests();
      } else if (_selectedTab == 'pet-requests') {
        pets = await ApiService.getMyPetRequests();
      } else {
        pets = [];
      }

      setState(() {
        _pets = pets;
        _cachedData[_selectedTab] = pets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    ApiService.clearToken();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
    try {
      await ApiService.logout();
    } catch (e) {
      print('Logout API error (ignored): $e');
    }
  }

  void _switchTab(String tab) {
    if (_selectedTab != tab) {
      setState(() {
        _selectedTab = tab;
        _pets = [];
      });
      _loadPets();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F7F5),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  // Custom Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFF4FD1C7),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (_selectedTab != 'all-pets')
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedTab = 'all-pets';
                              });
                              _loadPets();
                            },
                          ),
                        Expanded(
                          child: Text(
                            _selectedTab == 'all-pets'
                                ? 'Pet Adoption'
                                : _selectedTab == 'history'
                                ? 'History'
                                : _selectedTab == 'my-pets'
                                ? 'My Pets'
                                : _selectedTab == 'my-requests'
                                ? 'My Requests'
                                : 'Pet Requests',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (_selectedTab != 'all-pets')
                          const SizedBox(width: 48),
                      ],
                    ),
                  ),

                  // Tab Navigation
                  if (_selectedTab == 'all-pets')
                    Container(
                      color: const Color(0xFF4FD1C7),
                      padding: const EdgeInsets.only(
                        bottom: 16,
                        left: 12,
                        right: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildTabChip('History', 'history', Icons.history),
                          _buildTabChip('My Pets', 'my-pets', Icons.pets),
                          _buildTabChip(
                            'My requests',
                            'my-requests',
                            Icons.chat_bubble_outline,
                          ),
                          _buildTabChip(
                            'Pet Requests',
                            'pet-requests',
                            Icons.inbox_outlined,
                          ),
                          _buildTabChip('Log out', 'logout', Icons.logout),
                        ],
                      ),
                    ),

                  // Content
                  Expanded(
                    child: _selectedTab == 'logout'
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF4FD1C7),
                            ),
                          )
                        : _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF4FD1C7),
                            ),
                          )
                        : _pets.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: () => _loadPets(forceRefresh: true),
                            color: const Color(0xFF4FD1C7),
                            child: _selectedTab == 'my-requests'
                                ? _buildRequestsList()
                                : _selectedTab == 'history'
                                ? _buildHistoryList()
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _pets.length,
                                    itemBuilder: (context, index) {
                                      final pet = _pets[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        child: _buildPetCard(pet),
                                      );
                                    },
                                  ),
                          ),
                  ),
                ],
              ),

              // FAB inside card
              if (_selectedTab == 'all-pets')
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: FloatingActionButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddPetPage(),
                        ),
                      );

                      if (result == true) {
                        _cachedData.clear();
                        await _loadPets(forceRefresh: true);
                      }
                    },
                    backgroundColor: const Color(0xFF4FD1C7),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pets.length,
      itemBuilder: (context, index) {
        final request = _pets[index];
        final pet = request['pet'];
        final status = request['status']?.toString() ?? 'pending';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: pet != null && pet['image_url'] != null
                        ? Image.network(
                            pet['image_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.pets,
                                  size: 40,
                                  color: Color(0xFF4FD1C7),
                                ),
                              );
                            },
                          )
                        : const Center(
                            child: Icon(
                              Icons.pets,
                              size: 40,
                              color: Color(0xFF4FD1C7),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet?['pet_name']?.toString() ?? 'Unknown Pet',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pet?['breed']?.toString() ?? 'Unknown breed',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            status == 'pending'
                                ? Icons.hourglass_empty
                                : status == 'approved'
                                ? Icons.check_circle
                                : Icons.cancel,
                            size: 16,
                            color: status == 'pending'
                                ? Colors.orange
                                : status == 'approved'
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: status == 'pending'
                                  ? Colors.orange
                                  : status == 'approved'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (status == 'pending')
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _cancelRequest(request['id']),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _cancelRequest(int requestId) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text(
          'Are you sure you want to cancel this adoption request?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (shouldCancel == true) {
      try {
        await ApiService.cancelAdoptionRequest(requestId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _cachedData.remove('my-requests');
        await _loadPets(forceRefresh: true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    try {
      final DateTime parsedDate = DateTime.parse(date.toString());
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[parsedDate.month - 1]} ${parsedDate.day}, ${parsedDate.year}';
    } catch (e) {
      return date.toString();
    }
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pets.length,
      itemBuilder: (context, index) {
        final history = _pets[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: history['image_url'] != null
                            ? Image.network(
                                history['image_url'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(
                                      child: Icon(
                                        Icons.pets,
                                        size: 40,
                                        color: Color(0xFF4FD1C7),
                                      ),
                                    ),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.pets,
                                  size: 40,
                                  color: Color(0xFF4FD1C7),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            history['pet_name']?.toString() ?? 'Unknown Pet',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            history['breed']?.toString() ?? 'Unknown breed',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Owner Transfer
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.orange.withOpacity(0.2),
                            radius: 24,
                            child: const Icon(
                              Icons.person_outline,
                              size: 24,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            history['original_owner_name']?.toString() ??
                                'Unknown',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Original Owner',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 28,
                        color: const Color(0xFF4FD1C7),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(
                              0xFF4FD1C7,
                            ).withOpacity(0.2),
                            radius: 24,
                            child: const Icon(
                              Icons.person,
                              size: 24,
                              color: Color(0xFF4FD1C7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            history['new_owner_name']?.toString() ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'New Owner',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Completed on ${_formatDate(history['adoption_date'])}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabChip(String label, String value, IconData icon) {
    final isSelected = _selectedTab == value;

    return Expanded(
      child: GestureDetector(
        onTap: () async {
          if (value == 'logout') {
            final shouldLogout = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Log Out'),
                content: const Text('Are you sure you want to log out?'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4FD1C7),
                    ),
                    child: const Text(
                      'Log Out',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
            if (shouldLogout == true) _handleLogout();
          } else if (value == 'my-pets') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyPetsPage()),
            ).then((result) {
              if (result == true) {
                _cachedData.clear();
                _loadPets(forceRefresh: true);
              }
            });
          } else if (value == 'pet-requests') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PetRequestsPage()),
            );
          } else {
            _switchTab(value);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF4FD1C7).withOpacity(0.2)
                      : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? const Color(0xFF4FD1C7)
                      : Colors.white.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF4FD1C7)
                      : Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    switch (_selectedTab) {
      case 'history':
        message = 'No history yet';
        break;
      case 'my-pets':
        message = 'No pets posted yet';
        break;
      case 'my-requests':
        message = 'No adoption requests yet';
        break;
      case 'pet-requests':
        message = 'No pet requests received';
        break;
      default:
        message = 'No pets available';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pets, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _loadPets(forceRefresh: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4FD1C7),
            ),
            child: const Text('Refresh', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPetCard(dynamic pet) {
    return GestureDetector(
      onTap: () => _showPetDetails(pet),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          height: 140,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: Container(
                  width: 140,
                  height: 140,
                  color: Colors.grey[300],
                  child: pet['image_url'] != null
                      ? Image.network(
                          pet['image_url'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                                child: Icon(
                                  Icons.pets,
                                  size: 50,
                                  color: Color(0xFF4FD1C7),
                                ),
                              ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF4FD1C7),
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Icon(
                            Icons.pets,
                            size: 50,
                            color: Color(0xFF4FD1C7),
                          ),
                        ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pet['pet_name']?.toString() ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.pets,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  pet['breed']?.toString() ?? 'Unknown breed',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.cake,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${pet['age'] ?? 'N/A'} years',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: pet['listing_type'] == 'adopt'
                                  ? const Color(0xFF4FD1C7).withOpacity(0.2)
                                  : Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              pet['listing_type'] == 'adopt' ? 'Adopt' : 'Buy',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: pet['listing_type'] == 'adopt'
                                    ? const Color(0xFF4FD1C7)
                                    : Colors.orange,
                              ),
                            ),
                          ),
                          if (pet['price'] != null &&
                              (pet['price'] is num
                                  ? pet['price'] > 0
                                  : double.tryParse(pet['price'].toString()) !=
                                            null &&
                                        double.parse(pet['price'].toString()) >
                                            0))
                            Text(
                              '\$${pet['price']}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4FD1C7),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPetDetails(dynamic pet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Pet Image
              if (pet['image_url'] != null)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      height: 250,
                      color: Colors.grey[300],
                      child: Image.network(
                        pet['image_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                              child: Icon(
                                Icons.pets,
                                size: 80,
                                color: Color(0xFF4FD1C7),
                              ),
                            ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              Text(
                pet['pet_name']?.toString() ?? 'Unknown',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.pets,
                    pet['category']?.toString() ?? 'Unknown',
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.cake, '${pet['age']} years'),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    pet['gender'] == 'male' ? Icons.male : Icons.female,
                    pet['gender']?.toString() ?? 'Unknown',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Basic Info
              _buildDetailRow('Breed', pet['breed']?.toString() ?? 'Unknown'),
              _buildDetailRow('Color', pet['color']?.toString() ?? 'Unknown'),
              _buildDetailRow('Status', pet['status']?.toString() ?? 'Unknown'),

              // ✅ ADD ALLERGIES
              if (pet['allergies'] != null &&
                  pet['allergies'].toString().isNotEmpty)
                _buildDetailRow(
                  'Allergies',
                  pet['allergies']?.toString() ?? '-',
                ),

              // ✅ ADD MEDICATIONS
              if (pet['medications'] != null &&
                  pet['medications'].toString().isNotEmpty)
                _buildDetailRow(
                  'Medications',
                  pet['medications']?.toString() ?? '-',
                ),

              // ✅ ADD FOOD PREFERENCES
              if (pet['food_preferences'] != null &&
                  pet['food_preferences'].toString().isNotEmpty)
                _buildDetailRow(
                  'Food Preferences',
                  pet['food_preferences']?.toString() ?? '-',
                ),

              if (pet['description'] != null &&
                  pet['description'].toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  pet['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 24),

              if (_currentUserId == null ||
                  pet['user_id'] != _currentUserId) ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => AdoptionRequestDialog(pet: pet),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4FD1C7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      pet['listing_type'] == 'adopt'
                          ? 'Request Adoption'
                          : 'Buy Now',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4FD1C7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4FD1C7),
                      width: 2,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Color(0xFF4FD1C7),
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'This is your pet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4FD1C7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF4FD1C7).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF4FD1C7)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4FD1C7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    );
  }
}
