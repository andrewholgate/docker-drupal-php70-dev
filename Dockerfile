FROM andrewholgate/drupal-php70:0.3.0
MAINTAINER Andrew Holgate <andrewholgate@yahoo.com>

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y upgrade

# Install tools for documenting.
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install python-sphinx python-pip doxygen && \
    DEBIAN_FRONTEND=noninteractive pip install sphinx_rtd_theme breathe

# XML needed by PHPCodeSniffer 2.3+ and other developer tools.
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php7.0-xml

# Install XDebug 2.4.0
RUN wget https://github.com/xdebug/xdebug/archive/XDEBUG_2_4_0RC4.tar.gz && \
    tar zxvf XDEBUG_2_4_0RC4.tar.gz && \
    rm -f XDEBUG_2_4_0RC4.tar.gz && \
    cd xdebug-XDEBUG_2_4_0RC4 && \
    phpize && \
    ./configure --enable-xdebug && \
    make && \
    cp modules/xdebug.so /usr/lib/php/20151012/ && \
    rm -Rf ../xdebug-XDEBUG_2_4_0RC4

COPY xdebug.ini /etc/php/mods-available/xdebug.ini
RUN ln -s /etc/php/mods-available/xdebug.ini /etc/php/7.0/fpm/conf.d/20-xdebug.ini
COPY xdebug /usr/local/bin/xdebug
RUN chmod +x /usr/local/bin/xdebug

# Symlink log files.
RUN ln -s /var/log/xdebug/xdebug.log /var/www/log/

# Install JRE (needed for some testing tools like sitespeed.io) and libs for PhantomJS.
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install default-jre libfreetype6 libfontconfig

# Install Node 4.3.1 LTS
RUN cd /opt && \
  wget https://nodejs.org/dist/v4.3.1/node-v4.3.1-linux-x64.tar.gz && \
  tar -xzf node-v4.3.1-linux-x64.tar.gz && \
  mv node-v4.3.1-linux-x64 node && \
  cd /usr/local/bin && \
  ln -s /opt/node/bin/* . && \
  rm -f /opt/node-v4.3.1-linux-x64.tar.gz

USER ubuntu
RUN echo 'export PATH="$PATH:$HOME/.npm-packages/bin"' >> ~/.bashrc && \
    npm config set prefix '~/.npm-packages'
USER root

# Setup for Wraith
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install imagemagick && \
    gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 && \
    \curl -sSL https://get.rvm.io | bash -s stable --ruby && \
    /bin/bash -l -c "source /usr/local/rvm/scripts/rvm" && \
    /bin/bash -l -c "rvm default" && \
    /bin/bash -l -c "rvm rubygems current" && \
    /bin/bash -l -c "gem install wraith"

# Front-end tools
RUN npm install -g phantomjs

# Install XHProf
RUN wget https://github.com/RustJason/xhprof/archive/php7.tar.gz && \
    tar zxvf php7.tar.gz && \
    rm -f php7.tar.gz && \
    cd xhprof-php7/extension/ && \
    phpize && \
    ./configure --with-php-config=/usr/bin/php-config7.0 && \
    make && \
    sudo make install && \
    rm -Rf ../xhprof-php7
# Tests fail:
# make test && \

# Turn on PHP error reporting
RUN sed -ri 's/^display_errors\s*=\s*Off/display_errors = On/g' /etc/php/7.0/fpm/php.ini && \
    sed -ri 's/^display_errors\s*=\s*Off/display_errors = On/g' /etc/php/7.0/cli/php.ini  && \
    sed -ri 's/^error_reporting\s*=.*$/error_reporting = -1/g' /etc/php/7.0/fpm/php.ini && \
    sed -ri 's/^error_reporting\s*=.*$/error_reporting = -1/g' /etc/php/7.0/cli/php.ini && \
    sed -ri 's/^display_startup_errors\s*=\s*Off/display_startup_errors = On/g' /etc/php/7.0/fpm/php.ini && \
    sed -ri 's/^display_startup_errors\s*=\s*Off/display_startup_errors = On/g' /etc/php/7.0/cli/php.ini && \
    sed -ri 's/^track_errors\s*=\s*Off/track_errors = On/g' /etc/php/7.0/fpm/php.ini && \
    sed -ri 's/^track_errors\s*=\s*Off/track_errors = On/g' /etc/php/7.0/cli/php.ini && \
    sed -ri 's/^;xmlrpc_errors\s*=\s*0/xmlrpc_errors = 1/g' /etc/php/7.0/fpm/php.ini && \
    sed -ri 's/^;xmlrpc_errors\s*=\s*0/xmlrpc_errors = 1/g' /etc/php/7.0/cli/php.ini && \
    sed -ri 's/^zend.assertions\s*=\s*-1/zend.assertions = 1/g' /etc/php/7.0/fpm/php.ini && \
    sed -ri 's/^zend.assertions\s*=\s*-1/zend.assertions = 1/g' /etc/php/7.0/cli/php.ini

# Disable Google Pagespeed
RUN sed -ri 's/\s*ModPagespeed on/    ModPagespeed off/g' /etc/apache2/mods-available/pagespeed.conf

# Grant ubuntu user access to sudo with no password.
RUN apt-get -y install sudo && \
    echo "ubuntu ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    usermod -a -G sudo ubuntu

# Load custom .bashrc settings if available.
USER ubuntu
RUN echo 'LOCAL_BASHRC="$HOME/.local/bashrc"; test -f "${LOCAL_BASHRC}" && source "${LOCAL_BASHRC}"' >> ~/.bashrc
USER root

# Clean-up installation.
RUN DEBIAN_FRONTEND=noninteractive apt-get -y autoclean && \
    DEBIAN_FRONTEND=noninteractive apt-get -y autoremove

RUN service apache2 restart
RUN service php7.0-fpm start

# Expose additional ports for test tools.
EXPOSE 8080 9876 9000

CMD ["/usr/local/bin/run"]
