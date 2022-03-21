#!/bin/bash

if [ ! -n "$BASH" ]; then
	echo "Non-bash shell detected, fixing..."
	bash -c '. <('"$(command -v curl >/dev/null && echo 'curl -Ls' || echo 'wget -qO-')"' https://github.com/hikariatama/Hikka/master/install.sh) '"$*"
	exit $?
fi

# Modified version of https://stackoverflow.com/a/3330834/5509575
sp='/-\|'
spin() {
	printf '\b%.1s' "$sp"
	sp=${sp#?}${sp%???}
}
endspin() {
	printf '\r%s\n' "$@"
}

runin() {
	# Runs the arguments and spins once per line of stdout (tee'd to logfile), also piping stderr to logfile
	{ "$@" 2>>../hikka-install.log || return $?; } | while read -r line; do
		spin
		printf "%s\n" "$line" >>../ftg-install.log
	done
}

runout() {
	# Runs the arguments and spins once per line of stdout (tee'd to logfile), also piping stderr to logfile
	{ "$@" 2>>hikka-install.log || return $?; } | while read -r line; do
		spin
		printf "%s\n" "$line" >>hikka-install.log
	done
}

errorin() {
	endspin "$@"
	cat ../hikka-install.log
}
errorout() {
	endspin "$@"
	cat hikka-install.log
}

banner() {
	clear
	clear
	printf "\n\e[7;30;41m                    )  \e[0m"
	printf "\n\e[7;30;41m (               ( /(  \e[0m"
	printf "\n\e[7;30;41m )\\ )   (   (    )\\()) \e[0m"
	printf "\n\e[7;30;41m(()/(   )\\  )\\ |((_)\\  \e[0m"
	printf "\n\e[7;30;41m /((\e[7;30;42m_\e[7;30;41m)\e[7;30;42m_\e[7;30;41m((\e[7;30;42m_\e[7;30;41m)((\e[7;30;42m_\e[7;30;41m)|\e[7;30;42m_\e[7;30;41m((\e[7;30;42m_\e[7;30;41m) \e[0m"
	printf "\n\e[7;30;41m(_)\e[0m\e[7;30;42m/ __| __| __| |/ /  \e[0m"
	printf "\n\e[7;30;42m  | (_ | _|| _|  ' <   \e[0m"
	printf "\n\e[7;30;42m   \\___|___|___|_|\\_\\ \e[0m\n\n"

} # TODO: Replace banner

##############################################################################

banner
printf '%s\n' "The process takes around 3-7 minutes"
printf '%s' "Installing now...  "

##############################################################################

spin

touch hikka-install.log
if [ ! x"$SUDO_USER" = x"" ]; then
	chown "$SUDO_USER:" hikka-install.log
fi

if [ ! x"" = x"$DYNO" ] && ! command -v python >/dev/null; then
	# We are running in a heroku dyno without python, time to get ugly!
	runout git clone https://github.com/heroku/heroku-buildpack-python || {
		endspin "Bootstrap download failed!"
		exit 1
	}
	rm -rf .heroku .cache .profile.d requirements.txt runtime.txt .env
	mkdir .cache .env
	echo "python-3.9.6" >runtime.txt
	echo "pip" >requirements.txt
	STACK=heroku-18 runout bash heroku-buildpack-python/bin/compile /app /app/.cache /app/.env ||
		{
			endspin "Bootstrap install failed!"
			exit 1
		}
	rm -rf .cache
	export PATH="/app/.heroku/python/bin:$PATH" # Prefer the bootstrapped python, incl. pip, over the system one.
fi

if [ -d "Hikka/hikka" ]; then
	cd Hikka || {
		endspin "Error: Install git package and re-run installer"
		exit 6
	}
	DIR_CHANGED="yes"
fi
if [ -f ".setup_complete" ] || [ -d "hikka" -a ! x"" = x"$DYNO" ]; then
	# If ftg is already installed by this script, or its in Heroku and installed
	PYVER=""
	if echo "$OSTYPE" | grep -qE '^linux-gnu.*'; then
		PYVER="3"
	fi
	endspin "Existing installation detected"
	clear
	banner
	"python$PYVER" -m hikka "$@"
	exit $?
elif [ "$DIR_CHANGED" = "yes" ]; then
	cd ..
fi

##############################################################################

echo "Installing..." >hikka-install.log

if echo "$OSTYPE" | grep -qE '^linux-gnu.*' && [ -f '/etc/debian_version' ]; then
	PKGMGR="apt install -y"
	if [ ! "$(whoami)" = "root" ]; then
		# Relaunch as root, preserving arguments
		if command -v sudo >/dev/null; then
			endspin "Restarting as root..."
			echo "Relaunching" >>ftg-install.log
			sudo "$BASH" -c '. <('"$(command -v curl >/dev/null && echo 'curl -Ls' || echo 'wget -qO-')"' https://github.com/hikariatama/Hikka/master/install.sh) '"$*"
			exit $?
		else
			PKGMGR="true"
		fi
	else
		runout dpkg --configure -a
		runout apt update
	fi
	PYVER="3"
elif echo "$OSTYPE" | grep -qE '^linux-gnu.*' && [ -f '/etc/arch-release' ]; then
	PKGMGR="pacman -Sy --noconfirm"
	if [ ! "$(whoami)" = "root" ]; then
		# Relaunch as root, preserving arguments
		if command -v sudo >/dev/null; then
			endspin "Restarting as root..."
			echo "Relaunching" >>ftg-install.log
			sudo "$BASH" -c '. <('"$(command -v curl >/dev/null && echo 'curl -Ls' || echo 'wget -qO-')"' https://github.com/hikariatama/Hikka/master/install.sh) '"$*"
			exit $?
		else
			PKGMGR="true"
		fi
	fi
	PYVER="3"
elif echo "$OSTYPE" | grep -qE '^linux-android.*'; then
	runout apt update
	PKGMGR="apt install -y"
	PYVER=""
elif echo "$OSTYPE" | grep -qE '^darwin.*'; then
	if ! command -v brew >/dev/null; then
		ruby <(curl -fsSk https://raw.github.com/mxcl/homebrew/go)
	fi
	PKGMGR="brew install"
	PYVER="3"
else
	endspin "Unrecognised OS. Please follow https://t.me/hikka_talks"
	exit 1
fi

##############################################################################

runout $PKGMGR "python$PYVER" git || {  # skipcq
	errorout "Core install failed."
	exit 2
}

if echo "$OSTYPE" | grep -qE '^linux-gnu.*'; then
	runout $PKGMGR "python$PYVER-dev"  # skipcq
	runout $PKGMGR "python$PYVER-pip"  # skipcq
	runout $PKGMGR python3 python3-pip git python3-dev libwebp-dev libz-dev libjpeg-dev libopenjp2-7 libtiff5 ffmpeg imamgemagick libffi-dev libcairo2  # skipcq
elif echo "$OSTYPE" | grep -qE '^linux-android.*'; then
	runout $PKGMGR openssl libjpeg-turbo libwebp libffi libcairo build-essential libxslt libiconv  # skipcq
elif echo "$OSTYPE" | grep -qE '^darwin.*'; then
	runout $PKGMGR jpeg webp  # skipcq
fi

runout $PKGMGR neofetch dialog  # skipcq

##############################################################################

SUDO_CMD=""
if [ ! x"$SUDO_USER" = x"" ]; then
	if command -v sudo >/dev/null; then
		SUDO_CMD="sudo -u $SUDO_USER "
	fi
fi

# shellcheck disable=SC2086
${SUDO_CMD}rm -rf Hikka
# shellcheck disable=SC2086
runout ${SUDO_CMD}git clone https://github.com/hikariatama/Hikka/ || {
	errorout "Clone failed."
	exit 3
}
cd Hikka || {
	endspin "Error: Install git package and re-run installer"
	exit 7
}
# shellcheck disable=SC2086
runin ${SUDO_CMD}"python$PYVER" -m pip install --upgrade pip setuptools wheel --user
# shellcheck disable=SC2086
runin ${SUDO_CMD}"python$PYVER" -m pip install -r requirements.txt --upgrade --user --no-warn-script-location --disable-pip-version-check || {
	errorin "Requirements failed!"
	exit 4
}
endspin "Installation successful. Launching setup interface..."
rm -f ../ftg-install.log
touch .setup_complete
# shellcheck disable=SC2086,SC2015
${SUDO_CMD}"python$PYVER" -m hikka "$@" || {
	echo "Python scripts failed"
	exit 5
}