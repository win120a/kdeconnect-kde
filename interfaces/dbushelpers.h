/*
 * Copyright 2015 Aleix Pol Gonzalez <aleixpol@kde.org>
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

#ifndef DBUSHELPERS_H
#define DBUSHELPERS_H

#include <QDBusPendingReply>
#include <QTextStream>
#include <KLocalizedString>

template <typename T>
Q_REQUIRED_RESULT T blockOnReply(QDBusPendingReply<T> reply)
{
    reply.waitForFinished();
    if (reply.isError()) {
        QTextStream(stderr) << i18n("error: ") << reply.error().message() << endl;
        exit(1);
    }
    return reply.value();
}

void blockOnReply(QDBusPendingReply<void> reply)
{
    reply.waitForFinished();
    if (reply.isError()) {
        QTextStream(stderr) << i18n("error: ") << reply.error().message() << endl;
        exit(1);
    }
}

#endif
