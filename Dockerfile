FROM andrewholgate/drupal-php70:0.2.0
MAINTAINER Andrew Holgate <andrewholgate@yahoo.com>

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y upgrade

# Install tools for documenting.
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install python-sphinx python-pip doxygen && \
    DEBIAN_FRONTEND=noninteractive pip install sphinx_rtd_theme breathe

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php7.0-dev

# Install XDebug
RUN wget https://github.com/xdebug/xdebug/archive/XDEBUG_2_4_0RC2.tar.gz && \
    tar zxvf XDEBUG_2_4_0RC2.tar.gz && \
    cd xdebug-XDEBUG_2_4_0RC2 && \
    phpize && \
    ./configure --enable-xdebug && \
    make && \
    cp modules/xdebug.so /usr/lib/php/20151012/ && \
    cd .. && rm -Rf xdebug-XDEBUG_2_4_0RC2

COPY xdebug.ini /etc/php/mods-available/xdebug.ini
RUN ln -s /etc/php/mods-available/xdebug.ini /etc/php/7.0/cli/conf.d/20-xdebug.ini
RUN ln -s /etc/php/mods-available/xdebug.ini /etc/php/7.0/fpm/conf.d/20-xdebug.ini
# Symlink log files.
RUN ln -s /var/log/xdebug/xdebug.log /var/www/log/

# Install XHProf
#RUN wget https://github.com/phacility/xhprof/archive/master.tar.gz && \
#    tar zxvf master.tar.gz && \
#    cd xhprof-master/extension/ && \
#    phpize && \
#    ./configure --with-php-config=/usr/bin/php-config7.0 && \
#    make && \
#    make install && \
#    make test && \
#    cd .. && rm -RF xhprof-master

# Install JRE (needed for some testing tools like sitespeed.io) and libs for PhantomJS.
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install default-jre libfreetype6 libfontconfig

# Install Node 4.2.3
RUN cd /opt && \
  wget https://nodejs.org/dist/v4.2.3/node-v4.2.3-linux-x64.tar.gz && \
  tar -xzf node-v4.2.3-linux-x64.tar.gz && \
  mv node-v4.2.3-linux-x64 node && \
  cd /usr/local/bin && \
  ln -s /opt/node/bin/* . && \
  rm -f /opt/node-v4.2.3-linux-x64.tar.gz

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
    sed -ri 's/^;xmlrpc_errors\s*=\s*0/xmlrpc_errors = 1/g' /etc/php/7.0/cli/php.ini

# Grant ubuntu user access to sudo with no password.
RUN apt-get -y install sudo && \
    echo "ubuntu ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    usermod -a -G sudo ubuntu

# Clean-up installation.
RUN DEBIAN_FRONTEND=noninteractive apt-get -y autoclean && \
    DEBIAN_FRONTEND=noninteractive apt-get -y autoremove

RUN service apache2 restart
RUN service php7.0-fpm start

# Expose additional ports for test tools.
EXPOSE 8080 9876 9000

CMD ["/usr/local/bin/run"]
