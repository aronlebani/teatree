# Integration testing

## Script

1. Naviage to /signup
    * [ ] Login link should take you to /login
    * [ ] Signup link should take you back to /signup

2. Create an account
    * [ ] Should validate required fields
    * [ ] Should validate username format
    * [ ] Should validate email format
    * [ ] Should validate pasword minimum 8 characters
    * [ ] Submit should redirect to /admin
    * [ ] Name, email, username should be correct
    * [ ] Signing up with an existing email should return 409
    * [ ] Signing up with an existing username should return 409

3. Log out and log back in
    * [ ] Logging out should take you back to /login
    * [ ] Navigating to /admin should redirect to /login with a 401
    * [ ] Entering a non-registered email or an incorrect password should return 401
    * [ ] Logging in should redirect to /admin
    * [ ] Admin page should render

4. Edit user
    * [ ] Edit user page should render
    * [ ] Form shows correct initial values
    * [ ] Back button should take you to /admin
    4.1. Edit name, email
        * [ ] Should validate non-empty name
        * [ ] Should validate non-empty email
        * [ ] Should validate email format
        * [ ] Using an existing email should return 409
        * [ ] Submit should redirect to /admin
        * [ ] New name should be correct
        * [ ] New email should be correct
    4.2. Edit name and not email
        * [ ] Should not return 409
    4.3. Change password
        * [ ] Change password page should render
        * [ ] Should validate pasword minimum 8 characters
        * [ ] Should validate old password matches new password
        * [ ] If old password is incorrect, should return 401
        * [ ] If old password is correct, should redirect to /login
        4.3.1. Log in with new password
            * [ ] Should redirect to /admin

5. Edit profile
    * [ ] Edit profile page should render
    * [ ] Form should show correct initial values
    * [ ] Back button should take you to /admin
    5.1. Edit primary colour, background colour, profile image, profile image alt, css
        * [ ] Submit should redirect to /admin
        * [ ] New fields should be correct
    5.2. Edit any field except profile image
        * [ ] Should not udpate profile image
    5.3. Edit only profile image
        * [ ] Submit should redirect to /admin
        * [ ] New fields should be correct

6. Create link
    * [ ] New link page should render
    * [ ] Back button should take you to /admin
    * [ ] Should validate non-empty title
    * [ ] Should validate non-empty URL
    * [ ] Should validate URL format
    * [ ] Submit should redirect to /admin
    * [ ] New link should show in list

7. Edit link
    * [ ] Edit link page should render
    * [ ] Back button should take you to /admin
    * [ ] Form should show correct initial values
    * [ ] Should validate non-empty title
    * [ ] Should validate non-empty URL
    * [ ] Submit should redirect to /admin
    * [ ] New link name and URL should be correct

8. Delete link
    * [ ] Delete link should redirect to /admin
    * [ ] Link should not show in list

9. Enable mailchimp integration
    * [ ] Before enabling, public profile page should not show signup form
    * [ ] Edit mailchimp page should render
    * [ ] Back button should take you to /admin
    * [ ] Should validate non-empty API key
    9.1. Enter an invalid API key
        * [ ] Submit should return 400
        * [ ] Integration should still be disabled
    9.2. Enter a valid API key
        * [ ] Submit should redirect to /admin
        * [ ] Status should show "enabled"
        * [ ] Public profile should show signup form

10. Preview public profile
    * [ ] Public profile page should render
    * [ ] Username should be correct
    * [ ] Colours should be correct
    * [ ] Custom CSS should be applied
    * [ ] All links should show
    * [ ] All links should open correct URL in new tab
    * [ ] Mailchimp signup form should work
    10.1. Log out and preview public profile
        * [ ] Should return 404

11. Make live
    * [ ] "Make live" button should not be visible
    * [ ] "Live" status should show
    11.1. Preview public profile
        * [ ] Public profile page should render
    11.2. Log out and preview public profile
        * [ ] Public profile page should render

12. Log out and click "Forgot password"
    * [ ] Forgot password form should render
    * [ ] Should validate email not-empty
    * [ ] Should validate email format
    * [ ] Submit should show a confirmation page and send an email
    12.1. Click forgot password link on email
        * [ ] Should render reset password form
        * [ ] Should validate pasword minimum 8 characters
        * [ ] Should validate old password matches new password
        * [ ] Submit should redirect to /login
        12.1.1. Log in with new password
            * [ ] Should redirect to /admin

13. Permissions
    * [ ] Can't view profile that doesn't belong to logged in user
    * [ ] Can't edit profile that doesn't belong to logged in user
    * [ ] Can't view user that isn't logged in
    * [ ] Can't edit user that isn't logged in
    * [ ] Can't view link belonging to different profile
    * [ ] Can't edit link belonging to different profile
