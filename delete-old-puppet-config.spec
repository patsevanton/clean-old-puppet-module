%global _prefix /usr/local

Name:    clean-old-puppet-modules
Version: 1
Release: 3
Summary: Delete old puppet config in /usr/share/puppet/modules

Group:   Development Tools
URL:     https://gitlab.tools.russianpost.ru/service/delete-old-puppet-config
License: ASL 2.0
Source0: clean-old-puppet-modules.py
Source1: clean-old-puppet-modules-cron

%description

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p %{buildroot}/%{_bindir}
mkdir -p %{buildroot}/etc/cron.d
%{__install} -m 755 %{SOURCE0} %{buildroot}/%{_bindir}/%{name}.py
%{__install} -m 644 %{SOURCE1} %{buildroot}/etc/cron.d/clean-old-puppet-modules-cron

%files
%{_bindir}/%{name}.py
/etc/cron.d/clean-old-puppet-modules-cron
