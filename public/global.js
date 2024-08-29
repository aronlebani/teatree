function copy() {
	const copyText = document.getElementById("copy-text");

	navigator.clipboard.writeText(copyText.innerText);

	document.getElementById("copy").style.display = "none";
	document.getElementById("copied").style.display = "flex";

	setTimeout(() => {
		document.getElementById("copy").style.display = "flex";
		document.getElementById("copied").style.display = "none";
	}, 2000);
}

function validatePassword() {
	const password = document.getElementById("new-password");
	const confirmPassword = document.getElementById("confirm-password");

	const valid = password.value != confirmPassword.value
		? "Passwords don't match"
		: "";

	confirmPassword.setCustomValidity(valid);
}

function updateProfileURL() {
	const username = document.getElementById("username").value;
	document.getElementById("profile-url").innerText = username;
}
