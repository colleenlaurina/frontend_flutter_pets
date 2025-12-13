// import 'package:flutter/material.dart';

// class AccToggle extends StatefulWidget {
//   final Function(String)? onRoleChanged;

//   const AccToggle({super.key, this.onRoleChanged});

//   @override
//   State<AccToggle> createState() => _AccToggleState();
// }

// class _AccToggleState extends State<AccToggle> {
//   bool _isAdmin = false;

//   String get currentRole => _isAdmin ? 'admin' : 'user';

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         // User button
//         Expanded(
//           child: GestureDetector(
//             onTap: () {
//               setState(() {
//                 _isAdmin = false;
//               });
//               widget.onRoleChanged?.call('user');
//             },
//             child: Container(
//               padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//               decoration: BoxDecoration(
//                 color: !_isAdmin ? const Color(0xFF4FD1C7) : Colors.white,
//                 borderRadius: BorderRadius.circular(25),
//                 border: Border.all(color: const Color(0xFF4FD1C7), width: 2),
//                 boxShadow: !_isAdmin
//                     ? [
//                         BoxShadow(
//                           color: const Color(0xFF4FD1C7).withOpacity(0.3),
//                           blurRadius: 8,
//                           offset: const Offset(0, 3),
//                         ),
//                       ]
//                     : [],
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.person,
//                     size: 20,
//                     color: !_isAdmin ? Colors.white : const Color(0xFF4FD1C7),
//                   ),
//                   const SizedBox(width: 8),
//                   Text(
//                     'User',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                       color: !_isAdmin ? Colors.white : const Color(0xFF4FD1C7),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(width: 12),
//         // Admin button
//         Expanded(
//           child: GestureDetector(
//             onTap: () {
//               setState(() {
//                 _isAdmin = true;
//               });
//               widget.onRoleChanged?.call('admin');
//             },
//             child: Container(
//               padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//               decoration: BoxDecoration(
//                 color: _isAdmin ? const Color(0xFF4FD1C7) : Colors.white,
//                 borderRadius: BorderRadius.circular(25),
//                 border: Border.all(color: const Color(0xFF4FD1C7), width: 2),
//                 boxShadow: _isAdmin
//                     ? [
//                         BoxShadow(
//                           color: const Color(0xFF4FD1C7).withOpacity(0.3),
//                           blurRadius: 8,
//                           offset: const Offset(0, 3),
//                         ),
//                       ]
//                     : [],
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.admin_panel_settings,
//                     size: 20,
//                     color: _isAdmin ? Colors.white : const Color(0xFF4FD1C7),
//                   ),
//                   const SizedBox(width: 8),
//                   Text(
//                     'Admin',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                       color: _isAdmin ? Colors.white : const Color(0xFF4FD1C7),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';

class AccToggle extends StatefulWidget {
  final Function(String) onRoleChanged;

  const AccToggle({super.key, required this.onRoleChanged});

  @override
  _AccToggleState createState() => _AccToggleState();
}

class _AccToggleState extends State<AccToggle> {
  String _selectedRole = 'user';

  void _toggleRole(String role) {
    setState(() {
      _selectedRole = role;
    });
    widget.onRoleChanged(role);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
      ),
      padding: EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            'User',
            _selectedRole == 'user',
            () => _toggleRole('user'),
          ),
          _buildToggleButton(
            'Admin',
            _selectedRole == 'admin',
            () => _toggleRole('admin'),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected, VoidCallback onTap) {
    return Flexible(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 250),
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 24),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFF4FD1C7) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
