import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController changePasswordController = TextEditingController();
  TextEditingController genderController = TextEditingController();
  TextEditingController civilStatusController = TextEditingController();
  TextEditingController birthDateController = TextEditingController();
  late String errorMessage;
  late bool isError;

  @override
  void initState() {
    errorMessage = "This is an error message";
    isError = false;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void checkRegister(
    name,
    username,
    password,
    changePassword,
    gender,
    civilStatus,
    birthDate,
  ) {
    setState(() {
      if (name == "") {
        errorMessage = "Please input your name!";
        isError = true;
      } else if (username == "") {
        errorMessage = "Please input your username!";
        isError = true;
      } else if (password == "") {
        errorMessage = "Please input your password!";
        isError = true;
      } else if (changePassword == "") {
        errorMessage = "Please re-enter your password!";
        isError = true;
      } else if (password != changePassword) {
        errorMessage = "Passwords do not match!";
        isError = true;
      } else if (gender == "") {
        errorMessage = "Please input your gender!";
        isError = true;
      } else if (civilStatus == "") {
        errorMessage = "Please input your civil status!";
        isError = true;
      } else if (birthDate == "") {
        errorMessage = "Please input your birth date!";
        isError = true;
      } else {
        isError = false;
        // If registration is successful, navigate back to login
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 248, 240), // Light orange background
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 215, 120, 11), // Orange color
        title: const Text('Create Account', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              const Icon(
                Icons.store,
                size: 60,
                color: Color.fromARGB(255, 215, 120, 11),
              ),
              const SizedBox(height: 10),
              Text(
                'Register',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(height: 15),
              // Name Field
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline, color: Colors.grey[600]),
                  floatingLabelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),
              const SizedBox(height: 20),
              
              // Username Field
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person_outline, color: Colors.grey[600]),
                  floatingLabelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),
              const SizedBox(height: 20),
              
              // Password Field
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
                  floatingLabelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),
              const SizedBox(height: 20),
              
              // Confirm Password Field
              TextField(
                controller: changePasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
                  floatingLabelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),
              const SizedBox(height: 20),
              
              // Gender Field
              TextField(
                controller: genderController,
                decoration: InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: Icon(Icons.person_outline, color: Colors.grey[600]),
                  floatingLabelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),
              const SizedBox(height: 20),
              
              // Civil Status Field
              TextField(
                controller: civilStatusController,
                decoration: InputDecoration(
                  labelText: 'Civil Status',
                  prefixIcon: Icon(Icons.people_outline, color: Colors.grey[600]),
                  floatingLabelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),
              const SizedBox(height: 20),
              
              // Birth Date Field
              TextField(
                controller: birthDateController,
                decoration: InputDecoration(
                  labelText: 'Birth Date',
                  prefixIcon: Icon(Icons.calendar_today, color: Colors.grey[600]),
                  floatingLabelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
                readOnly: true,
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    birthDateController.text = "${picked.day}/${picked.month}/${picked.year}";
                  }
                },
              ),
              const SizedBox(height: 30),
              // Register Button
              ElevatedButton(
                onPressed: () {
                  checkRegister(
                    nameController.text,
                    usernameController.text,
                    passwordController.text,
                    changePasswordController.text,
                    genderController.text,
                    civilStatusController.text,
                    birthDateController.text,
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  'SIGN UP',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              
              // Error Message
              if (isError)
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Text(
                    errorMessage,
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              const SizedBox(height: 20),
              
              // Already have an account? Sign In
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

