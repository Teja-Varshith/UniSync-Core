import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:unisync/app/providers.dart';
import 'package:unisync/features/auth/auth_repository.dart';
import 'package:unisync/models/user_model.dart';

class FillTank extends ConsumerStatefulWidget {
  const FillTank({super.key});

  @override
  ConsumerState<FillTank> createState() => _FillTankScreenState();
}

class _FillTankScreenState extends ConsumerState<FillTank> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _aboutController = TextEditingController();
  final _pageController = PageController();
  
  String? _selectedCollege;
  int? _selectedSemester;
  int _currentPage = 0;
  bool _isLoading = false;

  final List<String> _colleges = [
    'GMR Institute of Technology',
    'Anil Neerukonda Institute of Technology',
    'MVGR College of Engeineering',
    'Narsaraopeta Engineering College',
    'JNTU Kakinada',
    'VR Siddhartha Engineering College',
    'Others',
  ];

  final List<int> _semesters = [1, 2, 3, 4, 5, 6, 7, 8];

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  int _calculateYear(int semester) {
    return ((semester + 1) ~/ 2);
  }

  void _nextPage() {
    if (_formKey.currentState!.validate()) {
      if (_currentPage == 1 && _selectedCollege == null) return;
      if (_currentPage == 2 && _selectedSemester == null) return;
      
      if (_currentPage < 3) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }


  Future<void> _submitProfile() async {
  setState(() => _isLoading = true);

  try {
    final repo = ref.read(AuthRepositoryProvider);
    final oldUser = ref.read(userProvider);

    print("updatinf the old user");

    final updatedUser = await repo.completeProfile(
      emailId: oldUser!.emailId,
      name: _nameController.text.trim(),
      collegeName: _selectedCollege!,
      semester: _selectedSemester!,
      year: _calculateYear(_selectedSemester!),
      about: _aboutController.text.trim().isEmpty
          ? null
          : _aboutController.text.trim(),
    );

    print("updated user");

    // ✅ update state ONLY with backend-confirmed data
    ref.read(userProvider.notifier).state = updatedUser;

  } catch (e) {
    // show error snackbar
  } finally {
    setState(() => _isLoading = false);
  }
}



  String _getYearEmoji(int year) {
    switch (year) {
      case 1: return 'Baby steps! 👶';
      case 2: return 'Getting there! 🚶';
      case 3: return 'Almost pro! 🏃';
      case 4: return 'Final boss level! 🎓';
      default: return '🎯';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.amber.shade600,
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
            child: Column(
              children: [
                const SizedBox(height: 40),
                Lottie.asset(
                  'assets/animations/login_lottie.json',
                  height: 180,
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(30),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Fill Your Tank! ⛽',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Faster than getting your attendance signed!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(4, (index) => 
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: _currentPage == index ? 24 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _currentPage == index ? Colors.black : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 25),
                            SizedBox(
                              height: 350,
                              child: PageView(
                                controller: _pageController,
                                physics: const NeverScrollableScrollPhysics(),
                                onPageChanged: (index) => setState(() => _currentPage = index),
                                children: [
                                  _buildNamePage(),
                                  _buildCollegePage(),
                                  _buildSemesterPage(),
                                  _buildAboutPage(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                if (_currentPage > 0)
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _previousPage,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.black,
                                        side: const BorderSide(color: Colors.black, width: 1.5),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Text(
                                        'Go Back',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                                if (_currentPage > 0) const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : () {
                                      if (_currentPage == 3) {
                                        _submitProfile();
                                      } else {
                                        _nextPage();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      elevation: 3,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Text(
                                            _currentPage == 3 ? 'Let\'s Go! 🚀' : 'Continue',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNamePage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What do your friends call you? 🙋',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          'No nicknames like "Chotu" or "Bhai" please 😅',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 18),
        TextFormField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Your awesome name',
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Come on, we need to call you something! 🤷';
            }
            if (value.trim().length < 3) {
              return 'That\'s too short! Are you "Neo"? 🤔';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCollegePage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Where\'s your brain factory? 🏫',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          'Where you\'re professionally confused 📚',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 18),
        CustomDropdown<String>(
          hint: 'Select your college',
          value: _selectedCollege,
          items: _colleges,
          onChanged: (value) => setState(() => _selectedCollege = value),
        ),
        if (_selectedCollege == null) ...[
          const SizedBox(height: 8),
          Text(
            '☝️ Pick one to continue!',
            style: TextStyle(fontSize: 11, color: Colors.red.shade700),
          ),
        ],
      ],
    );
  }

  Widget _buildSemesterPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Which semester? 📖',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          'How deep into the rabbit hole? 🐰',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.3,
          ),
          itemCount: _semesters.length,
          itemBuilder: (context, index) {
            final semester = _semesters[index];
            final isSelected = _selectedSemester == semester;
            return InkWell(
              onTap: () => setState(() => _selectedSemester = semester),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      semester.toString(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      'sem',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        if (_selectedSemester != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Year ${_calculateYear(_selectedSemester!)} - ${_getYearEmoji(_calculateYear(_selectedSemester!))}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.amber.shade900,
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '☝️ Tap a semester above!',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade900,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAboutPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Spill the beans! ☕',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          'What makes you YOU? (totally optional! 😌)',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 18),
        TextFormField(
          controller: _aboutController,
          maxLines: 5,
          maxLength: 200,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Tech geek? Coffee addict? Meme lord?',
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

// Custom Dropdown Widget
class CustomDropdown<T> extends StatelessWidget {
  final String hint;
  final T? value;
  final List<T> items;
  final Function(T?) onChanged;

  const CustomDropdown({
    super.key,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDropdownSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                value?.toString() ?? hint,
                style: TextStyle(
                  fontSize: 14,
                  color: value == null ? Colors.grey.shade600 : Colors.black,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade700),
          ],
        ),
      ),
    );
  }

  void _showDropdownSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                hint,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 15),
            Container(
              height: 1,
              color: Colors.grey.shade200,
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey.shade200,
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = value == item;
                  return InkWell(
                    onTap: () {
                      onChanged(item);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      color: isSelected ? Colors.grey.shade100 : Colors.white,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.toString(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: isSelected ? Colors.black : Colors.grey.shade800,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: Colors.black,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}