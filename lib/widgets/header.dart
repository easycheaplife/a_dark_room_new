import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/engine.dart';

/// Header displays the navigation tabs for different game modules
class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<Engine>(
      builder: (context, engine, child) {
        return Container(
          height: 50,
          color: Colors.black,
          child: Row(
            children: [
              // Room tab
              if (engine.activeModule?.name == 'Room')
                _buildTab(context, 'A Dark Room', true)
              else
                _buildTab(context, 'A Dark Room', false, onTap: () {
                  // Navigate to Room
                }),

              // Outside tab
              if (Provider.of<Engine>(context, listen: false).activeModule?.name == 'Outside')
                _buildTab(context, 'Outside', true)
              else
                _buildTab(context, 'Outside', false, onTap: () {
                  // Navigate to Outside
                }),

              // Path tab
              if (Provider.of<Engine>(context, listen: false).activeModule?.name == 'Path')
                _buildTab(context, 'Path', true)
              else
                _buildTab(context, 'Path', false, onTap: () {
                  // Navigate to Path
                }),

              // Fabricator tab
              if (Provider.of<Engine>(context, listen: false).activeModule?.name == 'Fabricator')
                _buildTab(context, 'Fabricator', true)
              else
                _buildTab(context, 'Fabricator', false, onTap: () {
                  // Navigate to Fabricator
                }),

              // Ship tab
              if (Provider.of<Engine>(context, listen: false).activeModule?.name == 'Ship')
                _buildTab(context, 'Ship', true)
              else
                _buildTab(context, 'Ship', false, onTap: () {
                  // Navigate to Ship
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTab(BuildContext context, String title, bool isSelected, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade800 : Colors.black,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // Add a location tab
  static Widget addLocation(String title, String name, dynamic module) {
    // This would create a tab for a module
    // In the original game, this would add a tab to the header
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
