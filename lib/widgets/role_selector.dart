import 'package:flutter/material.dart';

class RoleSelector extends StatelessWidget {

  final String role;
  final Function(String) onChanged;

  const RoleSelector({
    super.key,
    required this.role,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          "Register As",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),

        SizedBox(height: 10),

        Row(
          children: [

            Expanded(
              child: roleCard(
                "User",
                Icons.person,
                "user",
              ),
            ),

            SizedBox(width: 15),

            Expanded(
              child: roleCard(
                "Technician",
                Icons.medical_services,
                "technician",
              ),
            ),

          ],
        )

      ],
    );
  }

  Widget roleCard(String title, IconData icon, String value){

    bool selected = role == value;

    return GestureDetector(
      onTap: () {
        onChanged(value);
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Colors.blue : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [

            Icon(
              icon,
              size: 35,
              color: selected ? Colors.blue : Colors.grey,
            ),

            SizedBox(height: 8),

            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            )

          ],
        ),
      ),
    );

  }

}