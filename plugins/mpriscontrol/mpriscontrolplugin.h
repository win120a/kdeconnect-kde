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
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#ifndef MPRISCONTROLPLUGIN_H
#define MPRISCONTROLPLUGIN_H

#include <QString>
#include <QHash>
#include <QLoggingCategory>
#include <QDBusServiceWatcher>
#include <QSharedPointer>

#include <core/kdeconnectplugin.h>


class OrgFreedesktopDBusPropertiesInterface;
class OrgMprisMediaPlayer2PlayerInterface;

class MprisPlayer
{
public:
    MprisPlayer(const QString& serviceName, const QString& dbusObjectPath, const QDBusConnection& busConnection);
    MprisPlayer() = delete;

public:
    const QString& serviceName() const { return m_serviceName; }
    OrgFreedesktopDBusPropertiesInterface* propertiesInterface() const { return m_propertiesInterface.data(); }
    OrgMprisMediaPlayer2PlayerInterface* mediaPlayer2PlayerInterface() const { return m_mediaPlayer2PlayerInterface.data(); }

private:
    QString m_serviceName;
    QSharedPointer<OrgFreedesktopDBusPropertiesInterface> m_propertiesInterface;
    QSharedPointer<OrgMprisMediaPlayer2PlayerInterface> m_mediaPlayer2PlayerInterface;
};


#define PACKET_TYPE_MPRIS QStringLiteral("kdeconnect.mpris")

Q_DECLARE_LOGGING_CATEGORY(KDECONNECT_PLUGIN_MPRIS)

class MprisControlPlugin
    : public KdeConnectPlugin
{
    Q_OBJECT

public:
    explicit MprisControlPlugin(QObject* parent, const QVariantList& args);

    bool receivePacket(const NetworkPacket& np) override;
    void connected() override { }

private Q_SLOTS:
    void propertiesChanged(const QString& propertyInterface, const QVariantMap& properties);
    void seeked(qlonglong);

private:
    void serviceOwnerChanged(const QString& serviceName, const QString& oldOwner, const QString& newOwner);
    void addPlayer(const QString& serviceName);
    void removePlayer(const QString& serviceName);
    void sendPlayerList();
    void mprisPlayerMetadataToNetworkPacket(NetworkPacket& np, const QVariantMap& nowPlayingMap) const;
    bool sendAlbumArt(const NetworkPacket& np);

    QHash<QString, MprisPlayer> playerList;
    int prevVolume;
    QDBusServiceWatcher* m_watcher;

};

#endif
