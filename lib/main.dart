import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
void main() {
  runApp(const PastelBaggageApp());
}
// Author and repository details.
const authorName = 'SARAH NABILAH BINTI ABD WAHAB';
const matricNumber = '2024651438';
const courseName = 'CDCS251 - Computer Science Netcentrics';
const githubUrl =  'https://github.com/SarahNabilahWahab/excess_baggage_assignment';
const ink = Color(0xFF34334D);
const purple = Color(0xFF68548E);
const lavender = Color(0xFFECE4FA);
const mint = Color(0xFFE1F1E9);
const peach = Color(0xFFFFE9DC);
const background = Color(0xFFFAF8FD);
class PastelBaggageApp extends StatelessWidget {
  const PastelBaggageApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pastel Baggage',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: purple,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          foregroundColor: ink,
          centerTitle: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFD7CEE5)),
          ),
        ),
      ),
      home: const MainScreen(),
    );
  }
}
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}
class _MainScreenState extends State<MainScreen> {
  int selectedPage = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pastel Baggage',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      // IndexedStack preserves the calculator when visiting About.
      body: IndexedStack(
        index: selectedPage,
        children: const [
          HomePage(),
          AboutPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedPage,
        indicatorColor: lavender,
        onDestinationSelected: (index) {
          FocusManager.instance.primaryFocus?.unfocus();
          setState(() => selectedPage = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'About',
          ),
        ],
      ),
    );
  }
}
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  final formKey = GlobalKey<FormState>();
  final weightController = TextEditingController();
  final rateController = TextEditingController(text: '15');
  final resultKey = GlobalKey();  
  String ticketClass = 'Economy';
  bool useManualRate = false;
  double? calculatedWeight;
  double? calculatedRate;
  double? excessWeight;
  double? baggageCharge;
  double? serviceTax;
  double? totalPayable;
  double get allowance => ticketClass == 'Economy' ? 20 : 40;
  @override
  void dispose() {
    weightController.dispose();
    rateController.dispose();
    super.dispose();
  }
  // Clear an old result whenever the inputs change.
  void invalidateResult() {
    if (totalPayable == null) return;
    setState(() {
      totalPayable = null;
    });
  }
  String? validateNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName.';
    }
    final number = double.tryParse(value.trim());
    if (number == null || !number.isFinite || number < 0) {
      return 'Enter a valid number of 0 or more.';
    }
    return null;
  }
  void calculate() {
    FocusScope.of(context).unfocus();
    if (!formKey.currentState!.validate()) return;
    final weight = double.parse(weightController.text.trim());
    final rate = double.parse(rateController.text.trim());
    final excess = math.max(0.0, weight - allowance);
    final charge = excess * rate;
    final tax = charge * 0.08;
    final total = charge + tax;
    if (!charge.isFinite || !tax.isFinite || !total.isFinite) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The values are too large. Enter smaller values.'),
        ),
      );
      return;
    }
    setState(() {
      calculatedWeight = weight;
      calculatedRate = rate;
      excessWeight = excess;
      baggageCharge = charge;
      serviceTax = tax;
      totalPayable = total;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
  if (!mounted) return;
  final resultContext = resultKey.currentContext;
  if (resultContext != null) {
    Scrollable.ensureVisible(
      resultContext,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      alignment: 0.0,
    );
  }
});
  }
  void reset() {
    FocusScope.of(context).unfocus();
    formKey.currentState!.reset();
    weightController.clear();
    rateController.text = '15';
    setState(() {
      ticketClass = 'Economy';
      useManualRate = false;
      calculatedWeight = null;
      calculatedRate = null;
      excessWeight = null;
      baggageCharge = null;
      serviceTax = null;
      totalPayable = null;
    });
  }
  Widget numberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffix,
    required IconData icon,
    required TextInputAction action,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: action,
      inputFormatters: [
        TextInputFormatter.withFunction((oldValue, newValue) {
          // Allows whole numbers and decimals, including 42.5.
          return RegExp(r'^\d*\.?\d*$').hasMatch(newValue.text)
              ? newValue
              : oldValue;
        }),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        prefixIcon: Icon(icon, color: purple),
      ),
      validator: (value) => validateNumber(value, label.toLowerCase()),
      onChanged: (_) => invalidateResult(),
      onFieldSubmitted: (_) {
        if (action == TextInputAction.done) calculate();
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PastelPanel(
                color: lavender,
                child: Column(
                  children: [
                    Icon(Icons.luggage_rounded, size: 70, color: purple),
                    SizedBox(height: 12),
                    Text(
                      'Pack smart. Travel happy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: ink,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Estimate your excess baggage fee before you fly.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Your travel details',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 16),
                    numberField(
                      controller: weightController,
                      label: 'Baggage weight',
                      hint: 'Example: 25 or 42.5',
                      suffix: 'kg',
                      icon: Icons.monitor_weight_outlined,
                      action: TextInputAction.next,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Ticket class',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          avatar: const Icon(Icons.airline_seat_recline_normal),
                          label: const Text('Economy · 20 kg'),
                          selected: ticketClass == 'Economy',
                          selectedColor: lavender,
                          onSelected: (_) {
                            setState(() {
                              ticketClass = 'Economy';
                              if (!useManualRate) {
                                rateController.text = '15';
                              }
                              totalPayable = null;
                            });
                          },
                        ),
                        ChoiceChip(
                          avatar: const Icon(Icons.airline_seat_flat),
                          label: const Text('Business · 40 kg'),
                          selected: ticketClass == 'Business',
                          selectedColor: mint,
                          onSelected: (_) {
                            setState(() {
                              ticketClass = 'Business';
                              if (!useManualRate) {
                                rateController.text = '12';
                              }
                              totalPayable = null;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Included baggage allowance: '
                      '${allowance.toStringAsFixed(0)} kg',
                      style: const TextStyle(color: purple),
                    ),
                    const SizedBox(height: 20),
                    Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    // Select automatic or manual rate
    SegmentedButton<bool>(
      segments: const [
        ButtonSegment<bool>(
          value: false,
          label: Text('Automatic'),
          icon: Icon(Icons.auto_awesome),
        ),
        ButtonSegment<bool>(
          value: true,
          label: Text('Manual'),
          icon: Icon(Icons.edit_outlined),
        ),
      ],
      selected: {useManualRate},
      onSelectionChanged: (selection) {
        setState(() {
          useManualRate = selection.first;
          if (!useManualRate) {
            rateController.text =
                ticketClass == 'Economy' ? '15' : '12';
          }
          totalPayable = null;
        });
      },
    ),
    const SizedBox(height: 16),
    // Existing rate field
    TextFormField(
      controller: rateController,
      readOnly: !useManualRate,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        TextInputFormatter.withFunction((oldValue, newValue) {
          return RegExp(r'^\d*\.?\d*$').hasMatch(newValue.text)
              ? newValue
              : oldValue;
        }),
      ],
      decoration: InputDecoration(
        labelText: useManualRate
            ? 'Enter excess baggage rate'
            : 'Automatic excess baggage rate',
        suffixText: 'RM / kg',
        prefixIcon: const Icon(
          Icons.payments_outlined,
          color: purple,
        ),
        helperText: useManualRate
            ? 'Enter your preferred rate per kilogram.'
            : 'Sample rate based on your selected ticket class.',
        helperMaxLines: 2,
      ),
      validator: (value) =>
          validateNumber(value, 'excess baggage rate'),
      onChanged: (_) => invalidateResult(),
    ),
  ],
),
                    const SizedBox(height: 12),
                    const Text(
                      'An 8% service tax is assumed for this assignment.',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: calculate,
                      icon: const Icon(Icons.calculate_outlined),
                      label: const Text('Calculate fee'),
                      style: FilledButton.styleFrom(
                        backgroundColor: purple,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: reset,
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Reset'),
                    ),
                  ],
                ),
              ),
              if (totalPayable != null) ...[
                const SizedBox(height: 20),
                Semantics(
                  key: resultKey,
                  liveRegion: true,
                  child: PastelPanel(
                    color: excessWeight == 0 ? mint : peach,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          excessWeight == 0
                              ? Icons.check_circle_outline
                              : Icons.receipt_long_outlined,
                          size: 42,
                          color: ink,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          excessWeight == 0
                              ? 'Within your allowance!'
                              : 'Your baggage estimate',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: ink,
                          ),
                        ),
                        const SizedBox(height: 16),
                        resultRow('Ticket class', ticketClass),
                        resultRow(
                          'Baggage weight',
                          '${calculatedWeight!.toStringAsFixed(2)} kg',
                        ),
                        resultRow(
                          'Included allowance',
                          '${allowance.toStringAsFixed(0)} kg',
                        ),
                        resultRow(
                          'Excess baggage weight',
                          '${excessWeight!.toStringAsFixed(2)} kg',
                        ),
                        resultRow(
                          'Rate per kg',
                          'RM ${calculatedRate!.toStringAsFixed(2)}',
                        ),
                        resultRow(
                          'Excess baggage charge',
                          'RM ${baggageCharge!.toStringAsFixed(2)}',
                        ),
                        resultRow(
                          'Service tax (8%)',
                          'RM ${serviceTax!.toStringAsFixed(2)}',
                        ),
                        const Divider(height: 28),
                        const Text(
                          'TOTAL AMOUNT PAYABLE',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'RM ${totalPayable!.toStringAsFixed(2)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: ink,
                          ),
                        ),
                        if (excessWeight == 0) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Remaining allowance: '
                            '${(allowance - calculatedWeight!).toStringAsFixed(2)} kg',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
  Widget resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  Future<void> openGitHub(BuildContext context) async {
    try {
      final opened = await launchUrl(
        Uri.parse(githubUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        showLinkError(context);
      }
    } catch (_) {
      if (context.mounted) showLinkError(context);
    }
  }
  void showLinkError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to open the GitHub link.')),
    );
  }
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PastelPanel(
                color: lavender,
                child: Column(
                  children: [
                    // Visible application icon required on About.
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.luggage_rounded,
                        size: 54,
                        color: purple,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Pastel Baggage',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: ink,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text('A little help before your next flight.'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const PastelPanel(
                color: mint,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meet the developer',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: ink,
                      ),
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.person_outline),
                      title: Text('Name'),
                      subtitle: Text(authorName),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.badge_outlined),
                      title: Text('Matric number'),
                      subtitle: Text(matricNumber),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.school_outlined),
                      title: Text('Course'),
                      subtitle: Text(courseName),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PastelPanel(
                color: peach,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Project source code',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Tap the repository URL to open GitHub.'),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => openGitHub(context),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text(
                        githubUrl,
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '© ${DateTime.now().year} $authorName. All rights reserved.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Mobile Technology Individual Assignment',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class PastelPanel extends StatelessWidget {
  const PastelPanel({
    super.key,
    required this.color,
    required this.child,
  });
  final Color color;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }
}