# PHP Dockerfile for W Corp Cyber Range - Intentionally Vulnerable
FROM php:7.4-apache

# Install MySQL extension
RUN docker-php-ext-install mysqli pdo pdo_mysql

# Enable mod_rewrite
RUN a2enmod rewrite

# Set working directory
WORKDIR /var/www/html

# Copy PHP vulnerable components
COPY php/ /var/www/html/

# Create uploads directory with weak permissions
RUN mkdir -p /var/www/html/uploads && \
    chmod 777 /var/www/html/uploads

# Configure Apache to allow .htaccess overrides
RUN echo "<Directory /var/www/html>" >> /etc/apache2/apache2.conf && \
    echo "    AllowOverride All" >> /etc/apache2/apache2.conf && \
    echo "</Directory>" >> /etc/apache2/apache2.conf

# Expose port 80
EXPOSE 80

# Start Apache
CMD ["apache2-foreground"]
