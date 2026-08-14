/// Client OAuth "Web application" (`client_type: 3`) créé dans le même
/// projet Google Cloud que le client "Android" (package `com.example.joem`
/// + empreinte SHA-1 de signature) — voir la doc du projet pour la
/// procédure complète de création des deux clients.
///
/// Même sans backend à soi, Android exige ce client web comme
/// `serverClientId` pour `GoogleSignIn.instance` (API Credential Manager) :
/// c'est lui qui identifie l'app auprès de Google, le client "Android"
/// ne fait qu'autoriser l'usage de ce client web depuis ce package/cette
/// signature précis. Remplacer la valeur ci-dessous par le "Client ID" du
/// client web une fois créé sur https://console.cloud.google.com/apis/credentials.
const String kGoogleServerClientId =
    'REMPLACE_MOI.apps.googleusercontent.com';