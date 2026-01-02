
import 'dart:math';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routemaster/routemaster.dart';
import 'package:unisync/app/providers.dart';
import 'package:unisync/features/Campus_Mode/attendance/controller/attendance_controller.dart';
import 'package:unisync/features/Campus_Mode/attendance/view/subject_detail_screen.dart';
import 'package:unisync/models/course_model.dart';

class LiveAttendence extends ConsumerStatefulWidget {
  const LiveAttendence({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LiveAttendenceState();
}

class _LiveAttendenceState extends ConsumerState<LiveAttendence> {
  double _targetPercentage = 75.0;
  List attendanceData = [];
  bool isLoading = false;






  @override
  Widget build(BuildContext context) {
    final attedanceAsync = ref.watch(attendanceProvider);
    final userAsync = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [

                    if(userAsync!.cookie != null)
                    ...[
                       _appBar(),
                      _textHeader(),
                    _buildTargetSection(),
                    _buildTotalAttendance(attedanceAsync),
                    _buildSubjectwiseAttendance(attedanceAsync),
                    const SizedBox(height: 20),// Bottom padding
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

 


 
 Widget _buildTargetSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Target Attendance:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 60,
                height: 35,
                child: TextFormField(
                  // validator: (value) {
                  //   if (value == null || value.isEmpty) {
                  //     return 'Required';
                  //   }
                  //   final parsedValue = double.tryParse(value);
                  //   if (parsedValue != null && parsedValue > 0 && parsedValue < 100) {
                  //     return 'Enter valid %';
                  //   }
                  //   return null;
                  // },
                  initialValue: _targetPercentage.toInt().toString(),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    suffix: const Text('%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.blue[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.blue[600]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    filled: true,
                    fillColor: Colors.blue[50],
                  ),
                  onChanged: (value) {
                    final newValue = double.tryParse(value);
                    if (newValue != null && newValue > 0 && newValue < 100) {
                      setState(() {
                        _targetPercentage = newValue;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            'Set your desired Attendance and get instant report of how many classes you can Skip!🤫',
            style: TextStyle(
              fontSize: 13,
              color: Colors.blueGrey,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTotalAttendance(AsyncValue<List<CourseModel>> attendanceAsync) {
  return attendanceAsync.when(
    data: (courses) {
      if (courses.isEmpty) {
        return const SizedBox.shrink();
      }

      // Calculate overall attendance
      int totalPresent = courses.fold(0, (sum, course) => sum + course.present);
      int totalClasses = courses.fold(0, (sum, course) => sum + course.numberOfClasses);
      double overallPercentage = totalClasses > 0 ? (totalPresent / totalClasses) * 100 : 0.0;

      // Calculate classes needed/can bunk for target
      AttendanceCalculation calc = _calculateAttendanceForTarget(totalPresent, totalClasses, _targetPercentage);

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              overallPercentage >= _targetPercentage 
                ? const Color(0xFF10B981) 
                : const Color(0xFFEF4444),
              overallPercentage >= _targetPercentage 
                ? const Color(0xFF059669) 
                : const Color(0xFFDC2626),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Attendance stats
            Expanded(
              flex: 3,
              child: Row(
                spacing: 1,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCompactStat('Present', totalPresent.toString()),
                  _buildCompactStat('Total', totalClasses.toString()),
                  _buildCompactStat('Overall', '${overallPercentage.toStringAsFixed(1)}%'),
                ],
              ),
            ),
            // Divider
            Container(
              width: 1,
              height: 30,
              color: Colors.white.withOpacity(0.3),
              margin: const EdgeInsets.symmetric(horizontal: 12),
            ),
            // Action message
            Expanded(
              flex: 3,
              child: Text(
                calc.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    },
    loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 0, 208, 255)),
            ),
          ),
        ),
    error: (error, stackTrace) => const SizedBox.shrink(),
  );
}

Widget _buildCompactStat(String title, String value) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      Text(
        title,
        style: TextStyle(
          fontSize: 10,
          color: Colors.white.withOpacity(0.9),
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}













Widget _buildSubjectwiseAttendance(AsyncValue<List<CourseModel>> attendanceAsync) {
  return attendanceAsync.when(
    data: (data) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.04,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if(data.length == 0) ...[
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              Center(
                child: Text(
                  'Your Attendance data is not being updated yet',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            ...data.map((course) {
              final calc = _calculateAttendanceForTarget(
                  course.present, course.numberOfClasses, _targetPercentage);
              bool isAboveTarget = course.percentage >= _targetPercentage;
              bool isCritical = course.percentage < (_targetPercentage - 10);
              
              // Calculate future attendance for display
              String futureCalculation = "";
              if (calc.classesCount > 0) {
                if (calc.canBunk) {
                  int futurePresent = course.present;
                  int futureTotal = course.numberOfClasses + calc.classesCount;
                  double futurePercentage = (futurePresent / futureTotal) * 100;
                  futureCalculation = "→ $futurePresent/$futureTotal = ${futurePercentage.toStringAsFixed(1)}%";
                } else {
                  int futurePresent = course.present + calc.classesCount;
                  int futureTotal = course.numberOfClasses + calc.classesCount;
                  double futurePercentage = (futurePresent / futureTotal) * 100;
                  futureCalculation = "→ $futurePresent/$futureTotal = ${futurePercentage.toStringAsFixed(1)}%";
                }
              }

              return _buildSubjectCard(
                course: course,
                calc: calc,
                isAboveTarget: isAboveTarget,
                isCritical: isCritical,
                futureCalculation: futureCalculation,
              );
            }).toList(),
          ],
        ),
      );
    },
    loading: () {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.height * 0.05),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color.fromARGB(255, 0, 208, 255)
                ),
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading attendance data...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    },
    error: (error, stackTrace) {
      return Center(
        child: Container(
          margin: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFEF4444).withOpacity(0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: const Color(0xFFEF4444),
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                'Something went wrong!',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Unable to load attendance data. Please try again.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              // const SizedBox(height: 16),
              // ElevatedButton.icon(
              //   onPressed: () {
              //     // Add refresh functionality here
              //     // ref.refresh(attendanceProvider);
              //   },
              //   icon: const Icon(Icons.refresh_rounded),
              //   label: const Text('Retry'),
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: const Color(0xFFEF4444),
              //     foregroundColor: Colors.white,
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(12),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildSubjectCard({
  required CourseModel course,
  required dynamic calc,
  required bool isAboveTarget,
  required bool isCritical,
  required String futureCalculation,
}) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isSmallScreen = screenWidth < 400;
  
  // Determine colors based on status
  Color primaryColor = isAboveTarget 
    ? const Color(0xFF10B981) 
    : isCritical 
      ? const Color(0xFFEF4444)
      : const Color(0xFFF59E0B);
      
  Color secondaryColor = isAboveTarget 
    ? const Color(0xFF059669) 
    : isCritical 
      ? const Color(0xFFDC2626)
      : const Color(0xFFD97706);

  return Container(
    margin: EdgeInsets.only(
      bottom: 16,
      left: isSmallScreen ? 4 : 0,
      right: isSmallScreen ? 4 : 0,
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {


          // Navigate to subject details screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubjectDetailsScreen(
                subjectId: course.subjectId,
                subjectName: course.subjectName,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primaryColor.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject header
              _buildSubjectHeader(
                course: course,
                isAboveTarget: isAboveTarget,
                isCritical: isCritical,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                isSmallScreen: isSmallScreen,
              ),
              
              SizedBox(height: isSmallScreen ? 12 : 16),
              
              // Stats row
              _buildStatsRow(course, isSmallScreen),
              
              SizedBox(height: isSmallScreen ? 12 : 16),
              
              // Action container
              _buildActionContainer(
                calc: calc,
                course: course,
                isAboveTarget: isAboveTarget,
                isCritical: isCritical,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                futureCalculation: futureCalculation,
                isSmallScreen: isSmallScreen,
              ),
              
              // Navigation hint
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Tap for details',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: Colors.grey[500],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildSubjectHeader({
  required CourseModel course,
  required bool isAboveTarget,
  required bool isCritical,
  required Color primaryColor,
  required Color secondaryColor,
  required bool isSmallScreen,
}) {
  return Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.subjectName,
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (course.subjectId == true) ...[
              const SizedBox(height: 4),
              Text(
                course.subjectId!.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(width: 12),
      Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 10 : 12,
          vertical: isSmallScreen ? 4 : 6,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAboveTarget 
                ? Icons.trending_up_rounded 
                : isCritical 
                  ? Icons.trending_down_rounded
                  : Icons.trending_flat_rounded,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              '${course.percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildStatsRow(CourseModel course, bool isSmallScreen) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        _buildSubjectStatChip(
          'Present', 
          '${course.present}', 
          const Color(0xFF10B981),
          isSmallScreen,
        ),
        SizedBox(width: isSmallScreen ? 6 : 8),
        _buildSubjectStatChip(
          'Absent', 
          '${course.absent}', 
          const Color(0xFFEF4444),
          isSmallScreen,
        ),
        SizedBox(width: isSmallScreen ? 6 : 8),
        _buildSubjectStatChip(
          'Total', 
          '${course.numberOfClasses}', 
          const Color(0xFF6B7280),
          isSmallScreen,
        ),
      ],
    ),
  );
}

Widget _buildActionContainer({
  required dynamic calc,
  required CourseModel course,
  required bool isAboveTarget,
  required bool isCritical,
  required Color primaryColor,
  required Color secondaryColor,
  required String futureCalculation,
  required bool isSmallScreen,
}) {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
    decoration: BoxDecoration(
      color: primaryColor.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: primaryColor.withOpacity(0.2),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isAboveTarget 
                  ? Icons.check_circle_outline_rounded
                  : isCritical 
                    ? Icons.warning_outlined
                    : Icons.info_outline_rounded,
                size: 16,
                color: secondaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                calc.message,
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  color: secondaryColor,
                ),
              ),
            ),
          ],
        ),
        if (futureCalculation.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: primaryColor.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calculate_outlined,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${course.present}/${course.numberOfClasses} ',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF374151),
                          ),
                        ),
                        TextSpan(
                          text: futureCalculation,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            color: secondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

Widget _buildSubjectStatChip(String label, String value, Color color, bool isSmallScreen) {
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: isSmallScreen ? 8 : 12,
      vertical: isSmallScreen ? 6 : 8,
    ),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isSmallScreen ? 5 : 6,
          height: isSmallScreen ? 5 : 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: isSmallScreen ? 4 : 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: isSmallScreen ? 10 : 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isSmallScreen ? 10 : 12,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}























 
  // Mathematical calculation for attendance target
  AttendanceCalculation _calculateAttendanceForTarget(int present, int total, double targetPercentage) {
    if (total == 0) {
      return AttendanceCalculation(
        canBunk: false,
        classesCount: 0,
        message: "No classes yet",
      );
    }

    double currentPercentage = (present / total) * 100;
    
    if (currentPercentage >= targetPercentage) {
      // Calculate how many classes can be bunked
      // Formula: (present) / (total + x) = target/100
      // Solving for x: x = (present * 100 / target) - total
      int maxTotalClasses = (present * 100 / targetPercentage).floor();
      int canBunk = max(0, maxTotalClasses - total);
      
      if (canBunk > 0) {
        return AttendanceCalculation(
          canBunk: true,
          classesCount: canBunk,
          message: "You can Skip $canBunk more class${canBunk > 1 ? 'es' : ''}",
        );
      } else {
        return AttendanceCalculation(
          canBunk: false,
          classesCount: 0,
          message: "To maintain ${targetPercentage.toInt()}% you shouldn't skip any further classes.",
        );
      }
    } else {
      // Calculate how many classes need to be attended
      // Formula: (present + x) / (total + x) = target/100
      // Solving for x: x = (target * total - 100 * present) / (100 - target)
      int needToAttend = ((targetPercentage * total - 100 * present) / (100 - targetPercentage)).ceil();
      needToAttend = max(0, needToAttend);
      
      return AttendanceCalculation(
        canBunk: false,
        classesCount: needToAttend,
        message: "Attend next $needToAttend class${needToAttend > 1 ? 'es' : ''} to reach ${targetPercentage.toInt()}%",
      );
    }
  }

  Widget _appBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Routemaster.of(context).pop(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  ref.invalidate(attendanceProvider);
                  ref.refresh(attendanceProvider);


                  const snackBar = SnackBar(
                  elevation: 0,
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.transparent,
                  content: AwesomeSnackbarContent(
                    title: 'Attendance Refreshing....',
                    message:
                        'fetching latest attendance data, please wait.',

                    contentType: ContentType.warning,
                  ),
                );

                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(snackBar);

                  

                
                },
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 11),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Icon(
                          Icons.refresh,
                          size: 20,
                          color: Colors.white,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Refresh',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

   Widget _textHeader() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Text(
              'Smart Attendance',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Now attend classes like a pro!! 😎',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper class for attendance calculations
class AttendanceCalculation {
  final bool canBunk;
  final int classesCount;
  final String message;

  AttendanceCalculation({
    required this.canBunk,
    required this.classesCount,
    required this.message,
  });
}