
1. Bash script [setup.sh](./setup.sh) for automatic installation application from the repo
https://github.com/Manisha-Bayya/simple-django-project

   [according to task](./HW1.md)

2. The script was tested on Ubuntu-20 and Centos-7

3. The script check whether required MySQL and Python software is installed and whether the installed software is compatible with MySQL 8.0.X and Python 3.7.X
Whether any dependency(MySQL/Python) isn't installed the script proposes to a user to install it automatically.
Whether the user doesn't agree to install any missed dependency the script stops execution and exit

4. Configure these parameters/variables in this script or create a separate file with the name .env and host all/some of these variables in the .env file
- MYSQL_ROOT_PASSWORD
- MYSQL_USER
- MYSQL_PASSWORD
- EMAIL_HOST_USER
- EMAIL_HOST_PASSWORD

  Whether you use the script on Centos you should set up MySQL passwords according to the password policy:
  The default password policy implemented by `validate_password` requires that passwords contain at least one uppercase letter, onelowercase,  letter, one digit, and one special character and that the total password length is at least 8 characters.

  **Note**:
  During MySQL installation, you should enter the same root MySQL password as you defined in the variable MYSQL_ROOT_PASSWORD by installation  request.

5. [Shellcheck](https://www.shellcheck.net) linter check via command available [here](shellcheck-output.txt)
    ```
    shellcheck -x setup.sh
    ```
6. Help for script(the same description as here) available via command
    ```
    setup.sh --help
    ```
