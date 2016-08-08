# Project name

Mac Desktop Help Request Client

# Short Description

Mac desktop application that gathers some basic system information about the computer,
along with information from the user, and then posts the data (in JSON format) to a given URL.

# Extended Description

This application was made to help tech support groups. The application gathers the following
system information about the computer:

- Machine name
- Username of logged-in user
- Local IP address
- List of running processes
- Timestamp
- Name (submitted by user)
- Email (submitted by user)
- Comments (submitted by user)

The information is posted to the specified URL when the user presses the
submit button.

# Setup
Please fill in config data at top of [`AppDelegate.swift`](Info\ Gatherer/AppDelegate.swift#L20)

Required Fields are:
- `url` where the data is sent

Everything else should be filled out to improve user experiance.

# Credit

This project is based on a Windows application built by [Marie West](https://github.com/mariewest)

[https://github.com/mariewest/Desktop-Help-Request-Client](https://github.com/mariewest/Desktop-Help-Request-Client)

![Info Gatherer](/images/info_gatherer.png)
