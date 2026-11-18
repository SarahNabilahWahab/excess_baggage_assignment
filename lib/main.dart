// Prevents a negative excess weight with max().
import 'dart:math' as math;
// Provides Flutter widgets for the interface.
import 'package:flutter/material.dart';
// Provides the input formatter.
import 'package:flutter/services.dart';
// Opens the GitHub link.
import 'package:url_launcher/url_launcher.dart';
// Starts the Flutter app.
void main() {
  runApp(const PastelBaggageApp());
}
// Author and repository details.
// Set the developer details and GitHub URL here.
const authorName = 'SARAH NABILAH BINTI ABD WAHAB';
const matricNumber = '2024651438';
const courseName = 'CDCS251 - Computer Science Netcentrics';
const githubUrl =  'https://github.com/SarahNabilahWahab/excess_baggage_assignment';
// Set the app colours here.
const ink = Color(0xFF34334D);
const purple = Color(0xFF68548E);
const lavender = Color(0xFFECE4FA);
const mint = Color(0xFFE1F1E9);
const peach = Color(0xFFFFE9DC);
const background = Color(0xFFFAF8FD);
// Sets up the app theme and starting screen.
class PastelBaggageApp extends StatelessWidget {
  const PastelBaggageApp({super.key});
  @override
  Widget build(BuildContext context) {
    // Starts the app on MainScreen.
    return MaterialApp(
      title: '🧳 Baggage Fee Calculator',
      debugShowCheckedModeBanner: false,
      // Applies the shared colours and styles.
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
        // Sets the default text field styling.
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
// Tracks the selected tab.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}
class _MainScreenState extends State<MainScreen> {
  // 0 opens Home. 1 opens About.
  int selectedPage = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🧳 Baggage Fee Calculator',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      // IndexedStack preserves the calculator when visiting About.
      // Keeps the calculator inputs and results when switching tabs.
      body: IndexedStack(
        index: selectedPage,
        children: const [
          HomePage(),
          AboutPage(),
        ],
      ),
      // Shows the Home and About buttons.
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedPage,
        indicatorColor: lavender,
        // Hides the keyboard and switches tabs.
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
// Stores the calculator inputs and results.
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  // formKey validates and resets the form. Controllers hold the field text.
  // resultKey finds the results panel for scrolling.
  final formKey = GlobalKey<FormState>();
  final weightController = TextEditingController();
  final rateController = TextEditingController(text: '15');
  final resultKey = GlobalKey();
  // Starts in Economy with the automatic rate.
  String ticketClass = 'Economy';
  bool useManualRate = false;
  String? weightInputError;
  // Stores the latest calculation.
  // The results panel is hidden when totalPayable is null.
  double? calculatedWeight;
  double? calculatedRate;
  double? excessWeight;
  double? baggageCharge;
  double? serviceTax;
  double? totalPayable;
  // Set the baggage allowance here. Update the ticket button labels to match.
  double get allowance => ticketClass == 'Economy' ? 20 : 40;
  @override
  // Releases the text controllers when leaving this screen permanently.
  void dispose() {
    weightController.dispose();
    rateController.dispose();
    super.dispose();
  }
  // Clear an old result whenever the inputs change.
  // Hides the previous result when an input changes.
  void invalidateResult() {
    if (totalPayable == null) return;
    setState(() {
      totalPayable = null;
    });
  }
  // Accepts numbers of zero or more and shows an error for invalid input.
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
  // Returns an error for an invalid or overweight entry.
  String? validateWeight(String? value) {
    if (value == null || value.isEmpty) return 'Please enter baggage weight.';
    if (value.startsWith('-')) return 'Baggage weight cannot be negative.';
    if (!RegExp(r'^(?:\d+\.?\d*|\.\d+)$').hasMatch(value)) {
      return 'Use digits and one decimal point only.';
    }
    final weight = double.tryParse(value);
    if (weight == null || !weight.isFinite || weight > 100) {
      return 'Baggage weight cannot exceed 100 kg.';
    }
    return null;
  }
  // Rejects invalid edits while showing why they were rejected.
  TextEditingValue formatWeight(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.composing.isCollapsed) return newValue;
    final input = newValue.text;
    final error = input.isEmpty || input == '.' ? null : validateWeight(input);
    if (weightInputError != error || (error != null && totalPayable != null)) {
      setState(() {
        weightInputError = error;
        if (error != null) totalPayable = null;
      });
    }
    return error == null ? newValue : oldValue;
  }
  // Checks the inputs and calculates the total fee.
  void calculate() {
    FocusScope.of(context).unfocus();
    if (!formKey.currentState!.validate() || weightInputError != null) return;
    // Reads the baggage weight and rate from the text fields.
    final weight = double.parse(weightController.text.trim());
    final rate = double.parse(rateController.text.trim());
    // Subtracts the allowance from the baggage weight, with a minimum of zero.
    final excess = math.max(0.0, weight - allowance);
    // Multiplies the excess weight by the rate per kg.
    final charge = excess * rate;
    // Calculates tax at 8%. Update the two tax labels if you change this rate.
    final tax = charge * 0.08;
    // Adds the baggage charge and tax.
    final total = charge + tax;
    // Shows an error if the calculation produces a number too large to display.
    if (!charge.isFinite || !tax.isFinite || !total.isFinite) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The values are too large. Enter smaller values.'),
        ),
      );
      return;
    }
    setState(() {
      // Saves the results and refreshes the screen.
      calculatedWeight = weight;
      calculatedRate = rate;
      excessWeight = excess;
      baggageCharge = charge;
      serviceTax = tax;
      totalPayable = total;
    });
    // Waits for the results panel to appear before scrolling to it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final resultContext = resultKey.currentContext;
      if (resultContext != null) {
        // Scrolls to the result. Change the duration here to adjust the speed.
        Scrollable.ensureVisible(
          resultContext,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
          alignment: 0.0,
        );
      }
    });
  }
  // Clears the form and returns to Economy, Automatic and RM15 per kg.
  void reset() {
    FocusScope.of(context).unfocus();
    formKey.currentState!.reset();
    weightController.clear();
    rateController.text = '15';
    setState(() {
      ticketClass = 'Economy';
      useManualRate = false;
      weightInputError = null;
      calculatedWeight = null;
      calculatedRate = null;
      excessWeight = null;
      baggageCharge = null;
      serviceTax = null;
      totalPayable = null;
    });
  }
  // Builds a number field using the supplied label, unit and icon.
  Widget numberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffix,
    required IconData icon,
    required TextInputAction action,
  }) {
    final isWeight = controller == weightController;
    return TextFormField(
      controller: controller,
      forceErrorText: isWeight ? weightInputError : null,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: action,
      // Allows digits and one decimal point.
      inputFormatters: [
        if (isWeight)
          TextInputFormatter.withFunction(formatWeight)
        else
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
      // Shows the error returned by validateNumber().
      validator: isWeight
          ? validateWeight
          : (value) => validateNumber(value, label.toLowerCase()),
      // Hides the previous result when the user edits this field.
      onChanged: (_) => invalidateResult(),
      // Pressing Done on the keyboard runs the calculation.
      onFieldSubmitted: (_) {
        if (action == TextInputAction.done) calculate();
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    // Makes the page scrollable and limits its width to 600 pixels.
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
              // Groups the fields for validation and reset.
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
                      // Takes the total baggage weight in kg.
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
                    // Lets the ticket buttons wrap onto the next line.
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        // Selects Economy and sets the automatic rate to RM15 per kg.
                        // Set the Economy automatic rate here and in the default, reset and mode switch.
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
                        // Selects Business and sets the automatic rate to RM12 per kg.
                        // Set the Business automatic rate here and in the mode switch.
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
                        // Switches between Automatic and Manual rates.
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
                          // Shows the selected rate mode.
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
                          // Lets the user edit the rate in Manual mode.
                          readOnly: !useManualRate,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          // Allows digits and one decimal point.
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
                          // Shows the error returned by validateNumber().
                          validator: (value) =>
                              validateNumber(value, 'excess baggage rate'),
                          // Hides the previous result when the user edits this field.
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
                      // Runs calculate() when tapped.
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
                      // Runs reset() when tapped.
                      onPressed: reset,
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Reset'),
                    ),
                  ],
                ),
              ),
              // Displays the results after a successful calculation.
              if (totalPayable != null) ...[
                const SizedBox(height: 20),
                // Lets screen readers announce updates to the result.
                Semantics(
                  key: resultKey,
                  liveRegion: true,
                  child: PastelPanel(
                    // Uses mint for zero excess weight and peach for excess weight.
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
                        // Displays the fee breakdown and formats money to two decimal places.
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
                        // Shows how many kg are left in the allowance when there is no excess.
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
  // Displays a result label on the left and its value on the right.
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
// Shows developer details, the GitHub link and copyright.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  // Opens GitHub in an external app.
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
  // Shows a message if the GitHub link fails to open.
  void showLinkError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to open the GitHub link.')),
    );
  }
  @override
  Widget build(BuildContext context) {
    // Makes the page scrollable and limits its width to 600 pixels.
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
                      '🧳 Baggage Fee Calculator',
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
                      // Opens the GitHub link when tapped.
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
                // Uses the current year in the copyright notice.
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
// Builds a reusable rounded panel with a supplied colour and child widget.
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
