import { DashboardLayout } from "@/components/layout/DashboardLayout";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Separator } from "@/components/ui/separator";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Building2, Bell, Shield, Palette, Upload, Save } from "lucide-react";

const Settings = () => {
  return (
    <DashboardLayout
      title="Paramètres"
      subtitle="Configurez votre plateforme"
    >
      <Tabs defaultValue="company" className="space-y-6">
        <TabsList className="bg-card p-1 shadow-sm">
          <TabsTrigger value="company" className="gap-2">
            <Building2 className="w-4 h-4" />
            Entreprise
          </TabsTrigger>
          <TabsTrigger value="notifications" className="gap-2">
            <Bell className="w-4 h-4" />
            Notifications
          </TabsTrigger>
          <TabsTrigger value="security" className="gap-2">
            <Shield className="w-4 h-4" />
            Sécurité
          </TabsTrigger>
          <TabsTrigger value="appearance" className="gap-2">
            <Palette className="w-4 h-4" />
            Apparence
          </TabsTrigger>
        </TabsList>

        {/* Company Settings */}
        <TabsContent value="company" className="space-y-6">
          <div className="bg-card rounded-xl shadow-md p-6">
            <h3 className="text-lg font-heading font-semibold mb-6">
              Informations de l'entreprise
            </h3>

            {/* Logo Upload */}
            <div className="flex items-center gap-6 mb-8">
              <Avatar className="w-24 h-24 border-4 border-primary/20">
                <AvatarImage src="" />
                <AvatarFallback className="bg-primary text-primary-foreground text-2xl font-heading font-bold">
                  ES
                </AvatarFallback>
              </Avatar>
              <div>
                <h4 className="font-medium mb-2">Logo de l'entreprise</h4>
                <p className="text-sm text-muted-foreground mb-3">
                  Format PNG ou JPG, max 2MB
                </p>
                <Button variant="outline" className="gap-2">
                  <Upload className="w-4 h-4" />
                  Changer le logo
                </Button>
              </div>
            </div>

            <div className="grid gap-6 md:grid-cols-2">
              <div className="space-y-2">
                <Label htmlFor="company-name">Nom de l'entreprise</Label>
                <Input id="company-name" defaultValue="ESSIVI-Sarl" />
              </div>
              <div className="space-y-2">
                <Label htmlFor="phone">Téléphone</Label>
                <Input id="phone" defaultValue="+228 22 12 34 56" />
              </div>
              <div className="space-y-2">
                <Label htmlFor="email">Email</Label>
                <Input id="email" type="email" defaultValue="contact@essivi.tg" />
              </div>
              <div className="space-y-2">
                <Label htmlFor="address">Adresse</Label>
                <Input id="address" defaultValue="Lomé, Togo" />
              </div>
              <div className="space-y-2">
                <Label htmlFor="currency">Devise</Label>
                <Input id="currency" defaultValue="FCFA" disabled />
              </div>
              <div className="space-y-2">
                <Label htmlFor="timezone">Fuseau horaire</Label>
                <Input id="timezone" defaultValue="Africa/Lome (UTC+0)" disabled />
              </div>
            </div>

            <Separator className="my-6" />

            <h4 className="font-medium mb-4">Paramètres de livraison</h4>
            <div className="grid gap-6 md:grid-cols-2">
              <div className="space-y-2">
                <Label htmlFor="unit-price">Prix unitaire (FCFA/sachet)</Label>
                <Input id="unit-price" type="number" defaultValue="500" />
              </div>
              <div className="space-y-2">
                <Label htmlFor="validation-distance">Distance de validation (mètres)</Label>
                <Input id="validation-distance" type="number" defaultValue="2" />
              </div>
            </div>

            <div className="flex justify-end mt-6">
              <Button className="gradient-primary gap-2">
                <Save className="w-4 h-4" />
                Enregistrer les modifications
              </Button>
            </div>
          </div>
        </TabsContent>

        {/* Notifications Settings */}
        <TabsContent value="notifications" className="space-y-6">
          <div className="bg-card rounded-xl shadow-md p-6">
            <h3 className="text-lg font-heading font-semibold mb-6">
              Préférences de notification
            </h3>

            <div className="space-y-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="font-medium">Notifications par email</p>
                  <p className="text-sm text-muted-foreground">
                    Recevoir les rapports quotidiens par email
                  </p>
                </div>
                <Switch defaultChecked />
              </div>

              <Separator />

              <div className="flex items-center justify-between">
                <div>
                  <p className="font-medium">Notifications SMS</p>
                  <p className="text-sm text-muted-foreground">
                    Alertes critiques par SMS
                  </p>
                </div>
                <Switch />
              </div>

              <Separator />

              <div className="flex items-center justify-between">
                <div>
                  <p className="font-medium">Alertes de stock</p>
                  <p className="text-sm text-muted-foreground">
                    Notification quand le stock est faible
                  </p>
                </div>
                <Switch defaultChecked />
              </div>

              <Separator />

              <div className="flex items-center justify-between">
                <div>
                  <p className="font-medium">Résumé hebdomadaire</p>
                  <p className="text-sm text-muted-foreground">
                    Rapport de performance chaque lundi
                  </p>
                </div>
                <Switch defaultChecked />
              </div>
            </div>
          </div>
        </TabsContent>

        {/* Security Settings */}
        <TabsContent value="security" className="space-y-6">
          <div className="bg-card rounded-xl shadow-md p-6">
            <h3 className="text-lg font-heading font-semibold mb-6">
              Sécurité du compte
            </h3>

            <div className="space-y-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="font-medium">Authentification à deux facteurs (2FA)</p>
                  <p className="text-sm text-muted-foreground">
                    Ajouter une couche de sécurité supplémentaire
                  </p>
                </div>
                <Switch />
              </div>

              <Separator />

              <div className="flex items-center justify-between">
                <div>
                  <p className="font-medium">Déconnexion automatique</p>
                  <p className="text-sm text-muted-foreground">
                    Après 30 minutes d'inactivité
                  </p>
                </div>
                <Switch defaultChecked />
              </div>

              <Separator />

              <div>
                <p className="font-medium mb-4">Changer le mot de passe</p>
                <div className="grid gap-4 max-w-md">
                  <div className="space-y-2">
                    <Label htmlFor="current-password">Mot de passe actuel</Label>
                    <Input id="current-password" type="password" />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="new-password">Nouveau mot de passe</Label>
                    <Input id="new-password" type="password" />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="confirm-password">Confirmer le mot de passe</Label>
                    <Input id="confirm-password" type="password" />
                  </div>
                  <Button variant="outline" className="w-fit">
                    Mettre à jour le mot de passe
                  </Button>
                </div>
              </div>
            </div>
          </div>
        </TabsContent>

        {/* Appearance Settings */}
        <TabsContent value="appearance" className="space-y-6">
          <div className="bg-card rounded-xl shadow-md p-6">
            <h3 className="text-lg font-heading font-semibold mb-6">
              Personnalisation
            </h3>

            <div className="space-y-6">
              <div>
                <p className="font-medium mb-3">Couleur principale</p>
                <div className="flex gap-3">
                  {["#1E4A6E", "#2E7D32", "#C2410C", "#7C3AED", "#0891B2"].map(
                    (color) => (
                      <button
                        key={color}
                        className="w-10 h-10 rounded-lg border-2 border-transparent hover:border-ring transition-colors"
                        style={{ backgroundColor: color }}
                      />
                    )
                  )}
                </div>
              </div>

              <Separator />

              <div className="flex items-center justify-between">
                <div>
                  <p className="font-medium">Mode compact</p>
                  <p className="text-sm text-muted-foreground">
                    Réduire l'espacement pour afficher plus de contenu
                  </p>
                </div>
                <Switch />
              </div>

              <Separator />

              <div className="flex items-center justify-between">
                <div>
                  <p className="font-medium">Animations</p>
                  <p className="text-sm text-muted-foreground">
                    Activer les transitions et animations
                  </p>
                </div>
                <Switch defaultChecked />
              </div>
            </div>
          </div>
        </TabsContent>
      </Tabs>
    </DashboardLayout>
  );
};

export default Settings;
