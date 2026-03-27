import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:UniSync/app/providers.dart';
import 'package:UniSync/features/auth/auth_repository.dart';
import 'package:UniSync/models/user_model.dart';

class FillTank extends ConsumerStatefulWidget {
  const FillTank({super.key});

  @override
  ConsumerState<FillTank> createState() => _FillTankScreenState();
}

class _FillTankScreenState extends ConsumerState<FillTank> {
  static const String _othersCollegeOption = 'Others';
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _aboutController = TextEditingController();
  final _customCollegeController = TextEditingController();
  final _pageController = PageController();
   
  String? _selectedCollege;
  int? _selectedSemester;
  int _currentPage = 0;
  bool _isLoading = false;

  InputDecoration _buildInputDecoration({
    required String hintText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF8F8F8F),
        fontSize: 14,
      ),
      filled: true,
      fillColor: const Color(0xFF141414),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white70),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      counterStyle: const TextStyle(color: Color(0xFF8F8F8F)),
    );
  }

  final List<int> _semesters = [1, 2, 3, 4, 5, 6, 7, 8];

  bool get _isUsingCustomCollege => _selectedCollege == _othersCollegeOption;

  String? get _resolvedCollegeName {
    if (_isUsingCustomCollege) {
      final customCollege = _customCollegeController.text.trim();
      return customCollege.isEmpty ? null : customCollege;
    }
    final selectedCollege = _selectedCollege?.trim();
    if (selectedCollege == null || selectedCollege.isEmpty) return null;
    return selectedCollege;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    _customCollegeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  int _calculateYear(int semester) {
    return ((semester + 1) ~/ 2);
  }

  void _nextPage() {
    if (_formKey.currentState!.validate()) {
      if (_currentPage == 1 && _selectedCollege == null) return;
      if (_currentPage == 1 &&
          _isUsingCustomCollege &&
          _customCollegeController.text.trim().isEmpty) {
        return;
      }
      if (_currentPage == 2 && _selectedSemester == null) return;
      
      if (_currentPage < 3) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  Future<void> _saveCollegeForFutureUsers(String collegeName) async {
    final normalizedName = collegeName.trim();
    if (normalizedName.isEmpty) return;

    final firestore = ref.read(firebaseFirestoreProvider) as FirebaseFirestore;
    final docId = normalizedName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final collegeRef = firestore.collection('colleges').doc(docId);

    await collegeRef.set(
      {
        'name': normalizedName,
        'normalizedName': normalizedName.toLowerCase(),
        'isUserSubmitted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _seedTemporaryColleges() async {
    const sampleColleges = [
      'GMR Institute of Technology',
      'Anil Neerukonda Institute of Technology',
      'MVGR College of Engineering',
      'Narsaraopeta Engineering College',
      'JNTU Kakinada',
      'VR Siddhartha Engineering College',
      'Sri Venkateswara College of Engineering',
      'Vasireddy Venkatadri Institute of Technology',
    ];

    for (final college in sampleColleges) {
      await _saveCollegeForFutureUsers(college);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Temporary college seed added to Firebase'),
      ),
    );
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
    final collegeName = _resolvedCollegeName;
    if (collegeName == null) {
      setState(() => _isLoading = false);
      return;
    }

    if (_isUsingCustomCollege) {
      await _saveCollegeForFutureUsers(collegeName);
    }
    print("updatinf the old user");

    final updatedUser = await repo.completeProfile(
      name: _nameController.text.trim(),
      collegeName: collegeName,
      semester: _selectedSemester!,
      year: _calculateYear(_selectedSemester!),
      about: _aboutController.text.trim().isEmpty
          ? null
          : _aboutController.text.trim(),
    );

    print("updated user");

    // ✅ update state ONLY with backend-confirmed data
    ref.read(userProvider.notifier).state = updatedUser;
    _selectedCollege = collegeName;

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
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final pageHeight = screenHeight < 750 ? 280.0 : 350.0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: keyboardInset),
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
            child: Column(
              children: [
                const SizedBox(height: 20),
                Lottie.asset(
                  'assets/animations/login_lottie.json',
                  height: screenHeight < 750 ? 130 : 180,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                  color: const Color(0xFF222222),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.6),
                      blurRadius: 20,
                      spreadRadius: 5,
                      offset: const Offset(0, -10),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.05),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, -5),
                    ),
                  ],
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
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Faster than getting your attendance signed!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFFB3B3B3),
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
                              height: pageHeight,
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
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,color: Colors.white),
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
          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          'No nicknames like "Chotu" or "Bhai" please 😅',
          style: TextStyle(fontSize: 11, color: const Color(0xFFB3B3B3),),
        ),
        const SizedBox(height: 18),
        TextFormField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: Colors.white,
          decoration: _buildInputDecoration(
            hintText: 'Your awesome name',
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
    final firestore = ref.read(firebaseFirestoreProvider) as FirebaseFirestore;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: firestore.collection('colleges').orderBy('name').snapshots(),
      builder: (context, snapshot) {
        final colleges = snapshot.data?.docs
                .map((doc) => (doc.data()['name'] ?? '').toString().trim())
                .where((name) => name.isNotEmpty)
                .toSet()
                .toList() ??
            <String>[];

        colleges.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        if (!colleges.contains(_othersCollegeOption)) {
          colleges.add(_othersCollegeOption);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Where\'s your brain factory? 🏫',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 6),
            const Text(
              'Where you\'re professionally confused 📚',
              style: TextStyle(fontSize: 11, color: Color(0xFFB3B3B3)),
            ),
            const SizedBox(height: 18),
            CustomDropdown(
              hint: snapshot.connectionState == ConnectionState.waiting
                  ? 'Loading colleges...'
                  : 'Select your college',
              value: _selectedCollege,
              items: colleges,
              enabled: snapshot.connectionState != ConnectionState.waiting,
              emptyMessage: 'No colleges found yet. Pick Others and add yours.',
              onChanged: (value) => setState(() {
                _selectedCollege = value;
                if (value != _othersCollegeOption) {
                  _customCollegeController.clear();
                }
              }),
            ),
            // const SizedBox(height: 10),
            // Align(
            //   alignment: Alignment.centerRight,
            //   child: TextButton(
            //     onPressed: _seedTemporaryColleges,
            //     style: TextButton.styleFrom(
            //       foregroundColor: Colors.white70,
            //       padding: const EdgeInsets.symmetric(horizontal: 0),
            //     ),
            //     child: const Text(
            //       'Temp Seed Firebase',
            //       style: TextStyle(
            //         fontSize: 11,
            //         fontWeight: FontWeight.w700,
            //       ),
            //     ),
            //   ),
            // ),
            if (_isUsingCustomCollege) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _customCollegeController,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                cursorColor: Colors.white,
                textCapitalization: TextCapitalization.words,
                decoration: _buildInputDecoration(
                  hintText: 'Enter your college name',
                ),
                validator: (_) {
                  if (_currentPage != 1 || !_isUsingCustomCollege) return null;
                  if (_customCollegeController.text.trim().isEmpty) {
                    return 'Enter your college name so we can add it.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 6),
              const Text(
                'We will save this college for future users too.',
                style: TextStyle(fontSize: 11, color: Color(0xFFB3B3B3)),
              ),
            ],
            if (_selectedCollege == null) ...[
              const SizedBox(height: 8),
              Text(
                '☝️ Pick one to continue!',
                style: TextStyle(fontSize: 11, color: Colors.red.shade700),
              ),
            ],
            if (snapshot.hasError) ...[
              const SizedBox(height: 8),
              Text(
                'Could not load colleges right now. You can still use Others.',
                style: TextStyle(fontSize: 11, color: Colors.orange.shade300),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSemesterPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Which semester? 📖',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(
          'How deep into the rabbit hole? 🐰',
          style: TextStyle(fontSize: 11, color: Color(0xFFB3B3B3)),
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
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(
          'What makes you YOU? (totally optional! 😌)',
          style: TextStyle(fontSize: 11, color: Color(0xFFB3B3B3)),
        ),
        const SizedBox(height: 18),
        TextFormField(
          controller: _aboutController,
          maxLines: 5,
          maxLength: 200,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: Colors.white,
          decoration: _buildInputDecoration(
            hintText: 'Tech geek? Coffee addict? Meme lord?',
          ),
        ),
      ],
    );
  }
}

// Custom Dropdown Widget
class CustomDropdown extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final bool enabled;
  final String emptyMessage;

  const CustomDropdown({
    super.key,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
    this.emptyMessage = 'No options available',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? () => _showDropdownSheet(context) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF2C2C2C)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                value?.toString() ?? hint,
                style: TextStyle(
                  fontSize: 14,
                  color: value == null
                      ? (enabled ? const Color(0xFF8F8F8F) : Colors.white38)
                      : Colors.white,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: enabled ? Colors.white70 : Colors.white38,
            ),
          ],
        ),
      ),
    );
  }

  void _showDropdownSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        var query = '';

        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredItems = items
                .where((item) => item.toLowerCase().contains(query.toLowerCase()))
                .toList();
            final hasOthers = items.any(
              (item) => item.toLowerCase() == 'others',
            );
            final visibleItems = <String>[
              ...filteredItems,
              if (hasOthers && !filteredItems.any((item) => item.toLowerCase() == 'others'))
                items.firstWhere((item) => item.toLowerCase() == 'others'),
            ];

            return Container(
              height: MediaQuery.of(context).size.height * 0.78,
              decoration: const BoxDecoration(
                color: Color(0xFF121212),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
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
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      onChanged: (value) => setModalState(() => query = value),
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        hintText: 'Search college',
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(Icons.search, color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF1B1B1B),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white54),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(height: 1, color: Colors.white12),
                  Expanded(
                    child: visibleItems.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                emptyMessage,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: visibleItems.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              thickness: 1,
                              color: Colors.white12,
                            ),
                            itemBuilder: (context, index) {
                              final item = visibleItems[index];
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
                                  color: isSelected
                                      ? const Color(0xFF1E1E1E)
                                      : const Color(0xFF121212),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.white70,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.greenAccent,
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
            );
          },
        );
      },
    );
  }
}
