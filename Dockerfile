# Install dependencies
FROM appimagecrafters/appimage-builder
LABEL version="20220209"
RUN apt-get update && apt-get -y upgrade
RUN apt-get install -y build-essential software-properties-common python3.6 curl git wget unzip libgconf-2-4 gdb libstdc++6 libglu1-mesa fonts-droid-fallback lib32stdc++6 psmisc
RUN apt-get install -y --no-install-recommends cmake ninja-build clang build-essential pkg-config libgtk-3-dev liblzma-dev lcov
RUN apt-get clean

# Install appimagetool AppImage
RUN wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -O /opt/appimagetool

# workaround AppImage issues with Docker
RUN cd /opt/ && chmod +x appimagetool && sed -i 's|AI\x02|\x00\x00\x00|' appimagetool && ./appimagetool --appimage-extract
RUN mv /opt/squashfs-root /opt/appimagetool.AppDir
RUN ln -s /opt/appimagetool.AppDir/AppRun /usr/local/bin/appimagetool

# Clone the flutter repo
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter

# Set flutter path
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Enable flutter web
RUN flutter channel stable
RUN flutter upgrade
RUN flutter config --no-analytics
RUN flutter config --enable-web
RUN flutter config --enable-windows-desktop
RUN flutter config --enable-macos-desktop
RUN flutter config --enable-linux-desktop
RUN flutter doctor -v

RUN cd /tmp && flutter create app && cd app && flutter pub get \
    && flutter build web --release \
    && flutter build linux --release
COPY ./AppImageBuilder.yml /tmp/app/
RUN mkdir -p /tmp/app/AppDir/usr/share/icons/hicolor/64x64/apps/ \
    && cp /tmp/app/web/icons/Icon-192.png /tmp/app/AppDir/usr/share/icons/hicolor/64x64/apps/icon-64.png \
    && cp -r /tmp/app/build/linux/x64/release/bundle/* /tmp/app/AppDir/ \
    && cd /tmp/app && appimage-builder --recipe AppImageBuilder.yml --skip-tests \
    && cd / && cp -r /tmp/app/appimage-builder-cache /tmp/ && rm -rf /tmp/app

ENV PUB_HOSTED_URL=https://pub.flutter-io.cn