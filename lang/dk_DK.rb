


Localization.define('dk_DK') do |l|

  # Main menu
  l.store "Overview", "Overblik"
  l.store "Tutorial", "Introduktion"
  l.store "Browse", "Gennemse"
  l.store "Timeline", "Tidslinje"
  l.store "Files", "Filer"
  l.store "Reports", "Rapporter"
  l.store "Schedule", "Plan"
  l.store "New Task", "Ny Opgave"
  l.store "Preferences", "Indstillinger"
  l.store "Log Out", "Log ud"
  l.store "Clients", "Kunder"
  l.store "Client", "Kunde"
  l.store 'Search', 'S�g'
  l.store 'Users', 'Brugere'
  l.store 'User', 'Bruger'

  # Main layout
  l.store 'Hide', 'Skjul'
  l.store 'Views', 'Visninger'
  l.store 'Open Tasks', '�bne Opgaver'
  l.store 'My Open Tasks', 'Mine �bne Opgaver'
  l.store 'My In Progress Tasks', 'Mine igangv�rende opgaver'
  l.store 'Unassigned Tasks', 'Opgaver uden ansvarlig'
  l.store 'Shared', 'Delt'
  l.store 'Edit', 'Ret'
  l.store 'New', 'Ny'
  l.store 'Chat', 'Chat'
  l.store 'Notes', 'Notater'
  l.store 'Feedback? Suggestions? Ideas? Bugs?', 'Tilbagemeldinger? Forslag? Id�er? Fejlrapportering?'
  l.store 'Let me know', 'Lad mig vide det'
  l.store 'worked today', 'arbejdede i dag'
  l.store 'Online', 'Online'
  l.store 'Done working on <b>%s</b> for now.', 'Er f�rdig med at arbejde p� <b>%s</b> i denne omgang.' # %s = @task.name
  l.store 'ago', 'siden' # X days ago

  # Application Helper
  l.store 'today','i dag'
  l.store 'tomorrow', 'i morgen'
  l.store '%d day', ['en dag', '%d dage']
  l.store '%d week', ['en uge', '%d uger']
  l.store '%d month', ['en m�ned', '%d m�neder']
  l.store 'yesterday', 'i g�r'
  l.store '%d day ago', ['en dag siden', '%d dage siden']
  l.store '%d week ago', ['en uge siden', '%d uger siden']
  l.store '%d month ago', ['en m�ned siden', '%d m�neder siden']

  # DateHelper
  l.store 'less than a minute', 'mindre end et minut'
  l.store '%d minute', ['et minut', '%d minutter']
  l.store 'less than %d seconds', 'mindre end %d sekunder'
  l.store 'half a minute', 'et halvt minut'
  l.store 'about %d hour', ['cirka en time', 'cirka %d timer']

  # Activities
  l.store 'Top Tasks', 'Vigtigste Opgaver'
  l.store 'Newest Tasks', 'Nyeste Opgaver'
  l.store 'Recent Activities', 'Seneste aktiviteter'
  l.store 'Projects', 'Projekter'
  l.store 'Overall Progress', 'Samlet fremskridt'
  l.store '%d completed milestone', ['en f�rdig milep�l', '%d f�rdige milep�le']
  l.store '%d completed project', ['et f�rdigt projekt', '%d f�rdige projekter']
  l.store 'Edit project <b>%s</b>', 'Ret projektet <b>%s</b>'
  l.store 'Edit milestone <b>%s</b>', 'Ret milep�len <b>%s</b>'

  # Tasks
  l.store 'Tasks', 'Opgaver'
  l.store '[Any Client]', '[Alle Kunder]'
  l.store '[Any Project]', '[Alle Projekter]'
  l.store '[Any User]', '[Alle Brugere]'
  l.store '[Any Milestone]', '[Alle Milep�le]'
  l.store '[Any Status]', '[Alle Statusser]'
  l.store '[Unassigned]','[Uden Ansvarlig]'
  l.store 'Open', '�bn'
  l.store 'In Progress', 'Under Udvikling'
  l.store 'Closed', 'Lukket'
  l.store 'Won\'t Fix', 'Vil ikke udbedre'
  l.store 'Invalid', 'Ugyldig'
  l.store 'Duplicate', 'Dublet'
  l.store 'Archived', 'Arkiveret'
  l.store 'Group Tags', 'Gruppe Tag'
  l.store 'Save as View', 'Gem som billede'
  l.store 'Tags', 'Tag'
  l.store '[All Tags]', '[Alle Tags]'
  l.store 'Close <b>%s</b>', 'Luk <b>%s</b>'
  l.store "Stop working on <b>%s</b>.", 'Afslut arbejdet med <b>%s</b>.'
  l.store "Start working on <b>%s</b>. Click again when done.", 'Start med at arbejde p� <b>%s</b>. Klik igen for at afslutte.'
  l.store 'No one', 'Ingen'
  l.store "Revert <b>%s</b> to not completed status.", 'S�t <b>%s</b> til uf�rdig'
  l.store "Cancel working on <b>%s</b>.", 'Afbryd arbejdet med <b>%s</b>.'
  l.store "Move <b>%s</b> to the Archive.", 'Flyt <b>%s</b> til Arkivet.'
  l.store "Restore <b>%s</b> from the Archive.", 'Hent <b>%s</b> fra Arkivet.'
  l.store 'Information', 'Information'
  l.store 'Summary', 'Opsummering'
  l.store 'Description', 'Beskrivelse'
  l.store 'Comment', 'Kommentar'
  l.store 'Attach file', 'Vedh�ft fil'
  l.store 'Target', 'M�l'
  l.store 'Project', 'Projekt'
  l.store 'Milestone', 'Milep�l'
  l.store '[None]', '[Ingen]'
  l.store 'Assigned To', 'Ansvarlig'
  l.store 'Requested By', 'Efterspurg af'
  l.store 'Attributes', 'Attributter'

  l.store 'Type', 'Type'
  l.store 'Priority', 'Prioritet'
  l.store 'Severity', 'Alvorlighed'
  l.store 'Time Estimate', 'Forventet tidsforbrug'
  l.store 'Due Date', 'Deadline'
  l.store 'Show Calendar', 'Vis Kalender'
  l.store 'Notification', 'Varsling'
  l.store "Additional people to be notified on task changes<br />in addition to creator and asignee.<br/><br/>Ctrl-click to toggle.", 'Andre som skal varsles ved �ndringer<br/>ud over personen der har oprettet og den som er ansvarlig<br/><br/>Ctrl-klik for at v�lge.'
  l.store 'To:', 'Til:'
  l.store '[Delete]', '[Slet]'
  l.store 'Really delete %s?', 'Vil du virkelig slette %s?'
  l.store 'New Task', 'Ny Opgave'
  l.store 'Create', 'Opret'
  l.store 'Send notification emails', 'Send beked via email'
  l.store 'Created', 'Oprettet'
  l.store 'by', 'af' # Created by
  l.store 'Last Updated', 'Sidst opdateret'
  l.store 'Save', 'Gem'
  l.store 'and', 'og' # Save and ...

  l.store "Leave Open",'Hold �ben'
  l.store "Revert to Open",'�bn igen'
  l.store "Set in Progress",'S�t i gang'
  l.store "Leave as in Progress",'Hold i gang'
  l.store "Close",'Luk'
  l.store "Leave Closed",'Hold lukket'
  l.store "Set as Won't Fix",'S�t som Vil Ikke Udbedre'
  l.store "Leave as Won't Fix",'Behold som Vil Ikke Udbedre'
  l.store "Set as Invalid",'S�t som Ugyldig'
  l.store "Leave as Invalid",'Behold som Ugyldig'
  l.store "Set as Duplicate",'S�t som Kopi'
  l.store "Leave as Duplicate",'Behold som Kopi'
  l.store 'History', 'Historik'
  l.store 'Edit Log Entry', 'Ret i loggen'
  l.store 'Delete Log Entry', 'Slet log'
  l.store 'Really delete this log entry?', 'Vil du virkelig slette denne log?'

  l.store 'Task', 'Opgave'
  l.store 'New Feature', 'Ny Funktion'
  l.store 'Defect', 'Defekt'
  l.store 'Improvement', 'Forbedring'
  l.store 'Critical', 'Kritisk'
  l.store 'Urgent', 'Haster'
  l.store 'High', 'H�j'
  l.store 'Normal', 'Normal'
  l.store 'Low', 'Lav'
  l.store 'Lowest', 'Lavest'
  l.store 'Blocker', 'Blok�r'
  l.store 'Major', 'Stor'
  l.store 'Minor', 'Lillen'
  l.store 'Trivial', 'Triviel'

  l.store 'Start', 'Start'
  l.store 'Duration Worked', 'Arbejdedstid'

  # Timeline
  l.store '[All Time]', '[Al Tid]'
  l.store 'This Week', 'Denne Uge'
  l.store 'Last Week', 'Sidste Uge'
  l.store 'This Month', 'Denne M�ned'
  l.store 'Last Month', 'Sidste M�ned'
  l.store 'This Year', 'Dette �r'
  l.store 'Last Year', 'Sidte �r'
  l.store '[Any Type]', '[Alle Typer]'
  l.store 'Work Log', 'Arbejdslog'
  l.store 'Status Change', '�ndring af status'
  l.store 'Modified', '�ndret'
  l.store '[Prev]', '[Forrige]' # [Prev] 100 of 2000 entries [Next]
  l.store '[Next]', '[N�ste]' # [Prev] 100 of 2000 entries [Next]
  l.store 'of', 'af' # 100 of 2000 entries
  l.store 'entries..', 'elementer..' # 100 of 2000 entries

  # Project Files
  l.store 'Download', 'Download'
  l.store 'Delete', 'Slet'
  l.store '[New File]', '[Ny Fil]'
  l.store 'File', ['Fil', 'Filer']
  l.store 'Upload New File', 'Upload Ny Fil'
  l.store 'Name', 'Navn'
  l.store 'Upload', 'Upload'

  # Reports
  l.store 'Download CSV file of this report', 'Download CSV filen til denne rapport.'
  l.store 'Total', 'Total'
  l.store 'Report Configuration', 'Rapportindstillinger'
  l.store 'Report Type', 'Rapport Type'
  l.store 'Pivot', 'Pivot'
  l.store 'Audit', 'Tidstjek'
  l.store 'Time sheet', 'Timeseddel'
  l.store 'Time Range', 'Tidsrum'
  l.store 'Custom', 'Brugerdefineret'
  l.store 'Rows', 'R�kker'
  l.store 'Columns', 'Kolonner'
  l.store "Milestones", 'Milep�le'
  l.store "Date", 'Dato'
  l.store 'Task Status', 'Opgave Status'
  l.store "Task Type", 'Opgave Type'
  l.store "Task Priority", 'Opgave Prioritet'
  l.store "Task Severity", 'Opgave Alvorlighed'
  l.store 'From', 'Fra' # From Date
  l.store 'To', 'Til' # To Date
  l.store 'Sub-totals', 'Subtotaler'
  l.store 'Filter', 'Filter'
  l.store 'Advanced Options', 'Avancerede muligheder'
  l.store 'Status', 'Status'
  l.store 'Run Report', 'K�r Rapport'

  # Schedule

  # Search
  l.store 'Search Results', 'S�geresultater'
  l.store 'Activities', 'Aktiviteter'

  # Project list
  l.store 'Read', 'L�s'
  l.store 'Work', 'Arbejde'
  l.store 'Assign', 'Tildel'
  l.store 'Prioritize', 'Prioritere'
  l.store 'Grant', 'Giv adgang'
  l.store "Remove all access for <b>%s</b>?", 'Fjern al adgang til <b>%s</b>?'
  l.store "Grant %s access for <b>%s</b>?", 'Giv %s adgang til <b>%s</b>?'
  l.store "Can't remove <b>yourself</b> or the <b>project creator</b>!", 'Du kan ikke fjerne <b>dig selv</b> eller <b>projekt opretteren</b>!'
  l.store "Grant access to <b>%s</b>?", 'Giv adgagn til <b>%s</b>?'
  l.store 'Edit Project', 'Ret Projektet'
  l.store 'Delete Project', 'Slet Projekt'
  l.store 'Complete Project', 'Afslut Projekt'
  l.store 'New Milestone', 'Ny Milep�l'
  l.store 'Access To Project', 'Tilgang til Projektet'
  l.store 'Completed', 'Afsluttet'
  l.store 'Completed Projects', 'Afsluttede Projekter'
  l.store 'Revert', 'Genetabler'
  l.store 'Really revert %s?', 'Vil du virkelig genetablere %s?'

  # Milestones
  l.store 'Owner', 'Ansvarlig'
  l.store 'Edit Milestone', 'Ret Milep�l'
  l.store 'Delete Milestone', 'Slet Milep�l'
  l.store 'Complete Milestone', 'Afslut Milep�l'
  l.store 'Completed Milestones', 'Afsluttede Milep�le'

  # Users
  l.store 'Email', 'Email'
  l.store 'Last Login', 'Sidste login'
  l.store 'Offline', 'Offline'
  l.store 'Are your sure?', 'Er du sikker?'
  l.store 'Company', 'Firma'
  l.store '[New User]', '[Ny Bruger]'
  l.store '[Previous page]', '[Forrige side]'
  l.store '[Next page]', '[N�ste side]'
  l.store 'Edit User', 'Ret Bruger'

  l.store 'Options', 'Valg'
  l.store 'Location', 'Sted'
  l.store 'Administrator', 'Administrator'
  l.store 'Track Time', 'Registrer tid'
  l.store 'Use External Clients', 'Brug eksterne kunder'
  l.store 'Show Calendar', 'Vis kalender'
  l.store 'Show Tooltips', 'Vis hj�lpebobler'
  l.store 'Send Notifications', 'Send beskeder'
  l.store 'Receive Notifications', 'Modtag beskeder'

  l.store 'User Information', 'Brugerinformation'
  l.store 'Username', 'Brugernavn'
  l.store 'Password', 'Password'

  # Preferences
  l.store 'Preferences', 'Indstillinger'
  l.store 'Language', 'Sprog'
  l.store 'Time Format', 'Tidsformat'
  l.store 'Date Format', 'Datoformat'
  l.store 'Custom Logo', 'Brugerdefineret Logo'
  l.store 'Current logo', 'Nuv�rende Logo'
  l.store 'New logo', 'Nyt logo'
  l.store "(250x50px should look good. The logo will be shown up top instead of the ClockingIT one, and on your login page.)", "(250x50px burde se ok ud. Logoet vil blive vist i �verste venstre hj�rne p� din side.)"

  # Notes / Pages
  l.store 'Body', 'Indhold'
  l.store 'Preview', 'Vis'
  l.store 'New Note', 'Nyt notat'
  l.store 'Edit Note', 'Rediger notat'

  # Views
  l.store 'New View', 'Nyt visning'
  l.store 'Edit View', 'Rediger visning'
  l.store 'Delete View', 'Slet visning'
  l.store '[Active User]', '[Aktiv Bruger]'
  l.store 'Shared', 'Delt'

  # Clients
  l.store 'Contact', 'Kontakt'
  l.store 'New Client', 'Ny Kunde'
  l.store 'Contact email', 'Kontakt via email'
  l.store 'Contact name', 'Kontakt navn'
  l.store 'Client CSS', 'Kundens CSS'

  # Activities Controller
  l.store 'Tutorial completed. It will no longer be shown in the menu.', 'Introduktion er gennemf�rt. Den vil ikke l�ngere blive vist i menuen.'
  l.store 'Tutorial hidden. It will no longer be shown in the menu.', 'Introduktionen er skjult. Den vil ikke l�ngere blive vist i menuen.'

  # Customers Controller
  l.store 'Client was successfully created.', 'Kunde registreret.'
  l.store 'Client was successfully updated.', 'Kunde opdateret.'
  l.store 'Please delete all projects for %s before deleting it.', 'Slet alle projekter for %s f�r du sletter.'
  l.store "You can't delete your own company.", 'Du kan ikke slette dit eget firma.'
  l.store 'CSS successfully uploaded.', 'CSS uploadet.'
  l.store 'Logo successfully uploaded.', 'Logo uploadet.'

  # Milestones Controller
  l.store 'Milestone was successfully created.', 'Milep�l oprettet.'
  l.store 'Milestone was successfully updated.', 'Milep�l opdateret.'
  l.store '%s / %s completed.', '%s / %s er afsluttet.' # Project name / Milestone name completed.
  l.store '%s / %s reverted.', '%s / %s er blevet genskabt.' # Project name / Milestone name reverted.

  # Pages / Notes Controller
  l.store 'Note was successfully created.', 'Notat oprettet.'
  l.store 'Note was successfully updated.', 'Notat opdateret.'

  # Project Files Controller
  l.store 'No file selected for upload.', 'Der er ikke valgt nogen fil til upload.'
  l.store 'File too big.', 'Filen er for stor.'
  l.store 'File successfully uploaded.', 'Filen er uploadet.'

  # Projects Controller
  l.store 'Project was successfully created.', 'Projektet er oprettet.'
  l.store 'Project was successfully created. Add users who need access to this project.', 'Projektet blev oprettet. Giv adgang til brugere som skal v�re med i projektet.'
  l.store 'Project was successfully updated.', 'Projektet er blevet opdateret.'
  l.store 'Project was deleted.', 'Projektet blev slettet.'
  l.store '%s completed.', '%s afsluttet.'
  l.store '%s reverted.', '%s genskabt.'

  # Reports Controller
  l.store "Empty report, log more work!", 'T�m rapport, registrer mere tid!'

  # Tasks Controller
  l.store "You need to create a project to hold your tasks, or get access to create tasks in an existing project...", 'Du er n�d til at oprette et projekt, som kan indeholde dine opgaver. Ellers skal du have adgang til at oprette opgaver i et eksiterende projekt...'
  l.store 'Invalid due date ignored.', 'Ignererer ugyldig deadline-dato.'
  l.store 'Task was successfully created.', 'Opgave oprettet.'
  l.store 'Task was successfully updated.', 'Opgave opdateret.'
  l.store 'Log entry saved...', 'Arbejdsloggen blev gemt...'
  l.store "Unable to save log entry...", 'Arbejdsloggen blev <b>ikke</b> gemt...'
  l.store "Log entry already saved from another browser instance.", 'Arbejdsloggen er allerede blevet gemt fra en anden browser.'
  l.store 'Log entry deleted...', 'Registreringen i arbejdsloggen er nu slettet...'

  # Users Controller
  l.store 'User was successfully created. Remember to give this user access to needed projects.', 'Brugeren er blevet oprettet. Husk at give brugeren tilladelse til de n�dvendige projekter.'
  l.store "Error sending creation email. Account still created.", 'Det skete en fejl under afsendelsen af emailen men konto blev oprettet alligevel.'
  l.store 'User was successfully updated.', 'Brugeren er blevet opdateret.'
  l.store 'Preferences successfully updated.', 'Indstillingerne er blevet opdateret.'

  # Views Controller
  l.store "View '%s' was successfully created.", "Visningen '%s' er blevet oprettet."
  l.store "View '%s' was successfully updated.", "Visningen '%s' er blevet opdateret."
  l.store "View '%s' was deleted.", "Visningen '%s' er blevet slettet."

  # Wiki
  l.store 'Quick Reference', 'Hurtig Oversigt'
  l.store 'Full Reference', 'Fuld Oversigt'
  l.store 'or', 'eller'
  l.store 'Under revision by', 'Under revidering af'
  l.store 'Revision', 'Revision'
  l.store 'Linked from', 'Linket fra'

  # Reports
  l.store 'Today', 'I dag'
  l.store 'Week', 'Uge'

  # Dates
  l.store 'January', 'Januar'
  l.store 'February', 'Februar'
  l.store 'March', 'Mars'
  l.store 'April', 'April'
  l.store 'May', 'Maj'
  l.store 'June', 'Juni'
  l.store 'July', 'Juli'
  l.store 'August', 'August'
  l.store 'September', 'September'
  l.store 'October', 'Oktober'
  l.store 'November', 'November'
  l.store 'December', 'December'

  l.store 'Jan', 'Jan'
  l.store 'Feb', 'Feb'
  l.store 'Mar', 'Mar'
  l.store 'Apr', 'Apr'
  l.store 'May', 'Maj'
  l.store 'Jun', 'Jun'
  l.store 'Jul', 'Jul'
  l.store 'Aug', 'Aug'
  l.store 'Sep', 'Sep'
  l.store 'Oct', 'Okt'
  l.store 'Nov', 'Nov'
  l.store 'Dec', 'Dec'

  l.store 'Sunday', 'S�ndag'
  l.store 'Monday', 'Mandag'
  l.store 'Tuesday', 'Tirsdag'
  l.store 'Wednesday', 'Onsdag'
  l.store 'Thursday', 'Torsdag'
  l.store 'Friday', 'Fredag'
  l.store 'Saturday', 'L�rdag'

  l.store 'Sun', 'S�n'
  l.store 'Mon', 'Man'
  l.store 'Tue', 'Tir'
  l.store 'Wed', 'Ons'
  l.store 'Thu', 'Tor'
  l.store 'Fri', 'Fre'
  l.store 'Sat', 'L�r'

  # worked_nice
  l.store '[wdhm]', '[udtm]'
  l.store 'w', 'u'
  l.store 'd', 'd'
  l.store 'h', 't'
  l.store 'm', 'm'

  # Preferences
  l.store 'Duration Format', 'Varighedsformat'
  l.store 'Workday Length', 'Arbejdsdag'

  # Tasks filter
  l.store '[Without Milestone]', '[Uden Milep�l]'

  # Task tooltip
  l.store 'Progress', 'Fremskridt'

  # User Permissions
  l.store 'All', 'Alle'

  # Reports filter
  l.store '[Any Priority]', '[Alle Prioriteter]'
  l.store '[Any Severity]', '[Alle Alvorlighedsgrader]'

  # Preferences
  l.store '1w 2d 3h 4m', '1u 2d 3t 4m'
  l.store '1w2d3h4m', '1u2d3t4m'

  # Task
  l.store "Attachments", "Vedh�ftninger"
  l.store "Dependencies", "Afh�ngig af"
  l.store 'Add another dependency', "Ny afh�ngighed"
  l.store 'Remove dependency', "Fjern afh�ngighed"
  l.store "every", 'hver'
  l.store "[Any Task]", "[Alle Opgaver]"

  l.store 'day', 'dag' # every day
  l.store 'days', 'dage' # every 14 days
  l.store 'last', 'sidste' # every last thursday

  l.store 'Hide Waiting Tasks', 'Skjul ventende opgaver'
  l.store 'Signup Message', 'Personlig Besked'
  l.store 'The message will be included in the signup email.', 'Beskeden vil blive inkluderet i bekr�ftelses mailen der sendes ud.'
  l.store 'Depends on', 'Afh�ngig af'

  # Activities
  l.store 'Subscribe to the recent activities RSS feed', 'Abonner p� alle aktiviteter via RSS'

  # Project Files
  l.store '%d folder', ['%d mappe', '%d mapper']
  l.store '%d file', ['%d fil', '%d filer']

  # Email
  l.store 'Resolved', "L�st"
  l.store 'Updated', "Opdateret"
  l.store 'Reverted', "Genskabt"
  l.store 'Reassigned', "Tildelt"
end
