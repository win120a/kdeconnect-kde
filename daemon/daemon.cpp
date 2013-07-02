/**
 * Copyright 2013 Albert Vaca <albertvaka@gmail.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License or (at your option) version 3 or any later version
 * accepted by the membership of KDE e.V. (or its successor approved
 * by the membership of KDE e.V.), which shall act as a proxy
 * defined in Section 14 of version 3 of the license.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "daemon.h"
#include "networkpackage.h"
#include "packagereceivers/notificationpackagereceiver.h"
#include "packagereceivers/pausemusicpackagereceiver.h"
#include "announcers/avahiannouncer.h"
#include "announcers/fakeannouncer.h"
#include "devicelinks/echodevicelink.h"

#include <QtNetwork/QUdpSocket>
#include <QFile>
#include <QDBusConnection>

#include <KIcon>
#include <KConfigGroup>

#include <sstream>
#include <iomanip>
#include <iostream>

K_PLUGIN_FACTORY(KdeConnectFactory, registerPlugin<Daemon>();)
K_EXPORT_PLUGIN(KdeConnectFactory("kdeconnect", "kdeconnect"))

void Daemon::linkTo(DeviceLink* dl)
{

    linkedDevices.append(dl);

    Q_FOREACH (PackageReceiver* pr, packageReceivers) {
        QObject::connect(dl,SIGNAL(receivedPackage(const NetworkPackage&)),
                            pr,SLOT(receivePackage(const NetworkPackage&)));
    }

    KNotification* notification = new KNotification("pingReceived"); //KNotification::Persistent
    notification->setPixmap(KIcon("dialog-ok").pixmap(48, 48));
    notification->setComponentData(KComponentData("kdeconnect", "kdeconnect"));
    notification->setTitle(dl->device()->name());
    notification->setText("Succesfully connected");

}

Daemon::Daemon(QObject *parent, const QList<QVariant>&)
    : KDEDModule(parent)
    , config(KSharedConfig::openConfig("kdeconnectrc"))
{

    qDebug() << "GO GO GO!";

    //TODO: Do not hardcode the load of the package receivers
    //use: https://techbase.kde.org/Development/Tutorials/Services/Plugins
    packageReceivers.push_back(new NotificationPackageReceiver());
    packageReceivers.push_back(new PauseMusicPackageReceiver());

    //TODO: Do not hardcode the load of the device locators
    //use: https://techbase.kde.org/Development/Tutorials/Services/Plugins
    announcers.insert(new AvahiAnnouncer());
    announcers.insert(new FakeAnnouncer());

    //TODO: Add package emitters

    //Read remebered paired devices
    const KConfigGroup& known = config->group("devices").group("paired");
    const QStringList& list = known.groupList();
    const QString defaultName("unnamed");
    Q_FOREACH(QString id, list) {
        const KConfigGroup& data = known.group(id);
        const QString& name = data.readEntry<QString>("name",defaultName);
        pairedDevices.push_back(new Device(id,name));
    }


    QDBusConnection::sessionBus().registerService("org.kde.kdeconnect");


    //Listen to incomming connections
    Q_FOREACH (Announcer* a, announcers) {
        QObject::connect(a,SIGNAL(deviceConnection(DeviceLink*)),
                            this,SLOT(deviceConnection(DeviceLink*)));
    }

}

QString Daemon::listVisibleDevices()
{

    std::stringstream ret;

    ret << std::setw(20) << "ID";
    ret << std::setw(20) << "Name";
    ret << std::endl;

    Q_FOREACH (DeviceLink* d, visibleDevices) {
        ret << std::setw(20) << d->device()->id().toStdString();
        ret << std::setw(20) << d->device()->name().toStdString();
        ret << std::endl;
    }

    return QString::fromStdString(ret.str());

}

void Daemon::startDiscovery(int timeOut)
{
    qDebug() << "Start discovery";
    //Listen to incomming connections
    Q_FOREACH (Announcer* a, announcers) {
        a->setDiscoverable(true);
    }

}

bool Daemon::pairDevice(QString id)
{
    if (!visibleDevices.contains(id)) {
        return false;
    }
    config->group("devices").group("paired").group(id).writeEntry("name",visibleDevices[id]->device()->name());
    linkTo(visibleDevices[id]);
    return true;
}

bool Daemon::unpairDevice(QString id)
{
    /*qDebug() << "M'han passat" << id;
    foreach(QString c, config->group("devices").group("paired").groupList()) {
        qDebug() << "Tinc" << c;
    }*/
    if (!config->group("devices").group("paired").hasGroup(id)) {
        return false;
    }
    config->group("devices").group("paired").deleteGroup(id);
    return true;
}


QString Daemon::listLinkedDevices()
{
    QString ret;

    Q_FOREACH (DeviceLink* dl, linkedDevices) {
        if (!ret.isEmpty()) ret += "\n";
        //ret += dl->device()->name() + "(" + dl->device()->id() + ")";
        ret += dl->device()->id();
    }

    return ret;

}


void Daemon::deviceConnection(DeviceLink* dl)
{

    qDebug() << "deviceConnection";

    QString id = dl->device()->id();
    bool paired = false;
    Q_FOREACH (Device* d, pairedDevices) {
        if (id == d->id()) {
            paired = true;
            break;
        }
    }

    visibleDevices[dl->device()->id()] = dl;

    if (paired) {
        qDebug() << "Known device connected" << dl->device()->name();
        linkTo(dl);
    }
    else {
        qDebug() << "Unknown device connected" << dl->device()->name();
        emit deviceDiscovered(dl->device()->id(), dl->device()->name());
    }

}

Daemon::~Daemon()
{
    qDebug() << "SAYONARA BABY";
}

