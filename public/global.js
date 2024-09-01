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

function updateProfileURL() {
	const username = document.getElementById("username").value;
	document.getElementById("profile-url").innerText = username;
}
