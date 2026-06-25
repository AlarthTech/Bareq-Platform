import { Layout } from "@/components/layout";
import { useUser } from "@/hooks/use-auth";
import { useBookings, useUpdateBookingStatus } from "@/hooks/use-bookings";
import { useCleaners, useCreateCleaner } from "@/hooks/use-cleaners";
import { useState } from "react";
import { Redirect } from "wouter";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Calendar, UserCircle, DollarSign, CheckCircle2, Clock, XCircle, Plus, MapPin } from "lucide-react";

// Status badge helper
const StatusBadge = ({ status }: { status: string }) => {
  const styles: Record<string, string> = {
    pending: "bg-yellow-100 text-yellow-800 border-yellow-200",
    confirmed: "bg-blue-100 text-blue-800 border-blue-200",
    completed: "bg-green-100 text-green-800 border-green-200",
    cancelled: "bg-red-100 text-red-800 border-red-200",
  };
  
  const labels: Record<string, string> = {
    pending: "قيد الانتظار",
    confirmed: "مؤكد",
    completed: "مكتمل",
    cancelled: "ملغي",
  };

  return (
    <span className={`px-2.5 py-1 rounded-full text-xs font-bold border ${styles[status] || styles.pending}`}>
      {labels[status] || status}
    </span>
  );
};

export default function Dashboard() {
  const { data: user, isLoading: isUserLoading } = useUser();
  const { data: bookings = [], isLoading: isBookingsLoading } = useBookings();
  const { data: cleaners = [], isLoading: isCleanersLoading } = useCleaners();
  const updateStatus = useUpdateBookingStatus();
  const createCleaner = useCreateCleaner();
  
  const [isAddCleanerOpen, setIsAddCleanerOpen] = useState(false);
  const [newCleaner, setNewCleaner] = useState({
    name: "",
    bio: "",
    hourlyRate: 50,
    imageUrl: ""
  });

  if (isUserLoading) return (
    <Layout><div className="flex justify-center py-20"><div className="animate-spin w-10 h-10 border-b-2 border-primary rounded-full"></div></div></Layout>
  );

  if (!user) return <Redirect to="/login" />;

  // Filter data based on role
  const myBookings = user.role === "customer" 
    ? bookings.filter(b => b.customerId === user.id)
    // For companies, we'd ideally filter bookings by their cleaners, but for this MVP we'll show all if they are a company
    // assuming a simpler relational model or that the API filters it.
    // Let's filter bookings where cleanerId belongs to one of the company's cleaners.
    : bookings.filter(b => cleaners.filter(c => c.companyId === user.id).some(c => c.id === b.cleanerId));

  const myCleaners = user.role === "company" 
    ? cleaners.filter(c => c.companyId === user.id)
    : [];

  const handleAddCleaner = (e: React.FormEvent) => {
    e.preventDefault();
    createCleaner.mutate(
      {
        companyId: user.id,
        name: newCleaner.name,
        bio: newCleaner.bio,
        hourlyRate: Number(newCleaner.hourlyRate),
        imageUrl: newCleaner.imageUrl || "https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=500&q=80"
      },
      {
        onSuccess: () => {
          setIsAddCleanerOpen(false);
          setNewCleaner({name: "", bio: "", hourlyRate: 50, imageUrl: ""});
        }
      }
    );
  };

  return (
    <Layout>
      <div className="bg-muted/30 border-b border-border py-8">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <h1 className="text-3xl font-display font-black text-foreground mb-2">لوحة التحكم</h1>
          <p className="text-muted-foreground flex items-center gap-2">
            <UserCircle className="w-5 h-5" />
            {user.name} <span className="bg-primary/10 text-primary px-2 py-0.5 rounded text-xs font-bold mr-2">{user.role === 'company' ? 'شركة' : 'عميل'}</span>
          </p>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        
        {/* Company Section: Manage Cleaners */}
        {user.role === "company" && (
          <div className="mb-16">
            <div className="flex justify-between items-center mb-6">
              <h2 className="text-2xl font-bold font-display text-foreground">طاقم العمل (العاملات)</h2>
              
              <Dialog open={isAddCleanerOpen} onOpenChange={setIsAddCleanerOpen}>
                <DialogTrigger asChild>
                  <Button className="rounded-xl"><Plus className="w-4 h-4 ml-2" /> إضافة عاملة</Button>
                </DialogTrigger>
                <DialogContent className="sm:max-w-md rounded-3xl p-6" dir="rtl">
                  <DialogHeader>
                    <DialogTitle className="text-2xl font-bold">إضافة عاملة جديدة</DialogTitle>
                  </DialogHeader>
                  <form onSubmit={handleAddCleaner} className="space-y-4 mt-4">
                    <div className="space-y-2">
                      <Label>الاسم الكامل</Label>
                      <Input required value={newCleaner.name} onChange={e => setNewCleaner({...newCleaner, name: e.target.value})} className="rounded-xl" />
                    </div>
                    <div className="space-y-2">
                      <Label>نبذة عن الخبرة</Label>
                      <Textarea value={newCleaner.bio} onChange={e => setNewCleaner({...newCleaner, bio: e.target.value})} className="rounded-xl resize-none" />
                    </div>
                    <div className="space-y-2">
                      <Label>السعر بالساعة (ريال)</Label>
                      <Input type="number" required min="1" value={newCleaner.hourlyRate} onChange={e => setNewCleaner({...newCleaner, hourlyRate: Number(e.target.value)})} className="rounded-xl" />
                    </div>
                    <div className="space-y-2">
                      <Label>رابط الصورة (اختياري)</Label>
                      <Input type="url" dir="ltr" value={newCleaner.imageUrl} onChange={e => setNewCleaner({...newCleaner, imageUrl: e.target.value})} className="rounded-xl" placeholder="https://..." />
                    </div>
                    <Button type="submit" className="w-full rounded-xl mt-4" disabled={createCleaner.isPending}>
                      {createCleaner.isPending ? "جاري الحفظ..." : "حفظ بيانات العاملة"}
                    </Button>
                  </form>
                </DialogContent>
              </Dialog>
            </div>

            {isCleanersLoading ? (
               <div className="h-32 bg-muted rounded-2xl animate-pulse"></div>
            ) : myCleaners.length === 0 ? (
              <div className="bg-card border border-dashed border-border rounded-2xl p-10 text-center text-muted-foreground">
                لا يوجد عاملات مضافات بعد. أضف عاملتك الأولى لبدء استقبال الحجوزات.
              </div>
            ) : (
              <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-6">
                {myCleaners.map(cleaner => (
                  <div key={cleaner.id} className="bg-card border rounded-2xl p-4 flex items-center gap-4 shadow-sm hover:shadow-md transition-shadow">
                    <img src={cleaner.imageUrl || ""} alt={cleaner.name} className="w-16 h-16 rounded-xl object-cover bg-muted" />
                    <div>
                      <h4 className="font-bold text-lg">{cleaner.name}</h4>
                      <p className="text-sm text-primary font-medium">{cleaner.hourlyRate} ريال / ساعة</p>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* Bookings Section */}
        <div>
          <h2 className="text-2xl font-bold font-display text-foreground mb-6">
            {user.role === 'customer' ? 'سجل حجوزاتي' : 'حجوزات العاملات'}
          </h2>

          {isBookingsLoading ? (
            <div className="space-y-4">
              {[1,2,3].map(i => <div key={i} className="h-24 bg-muted rounded-2xl animate-pulse"></div>)}
            </div>
          ) : myBookings.length === 0 ? (
            <div className="bg-card border border-dashed border-border rounded-3xl p-16 text-center">
              <Calendar className="w-12 h-12 text-muted-foreground mx-auto mb-4 opacity-50" />
              <p className="text-xl font-bold text-foreground">لا يوجد حجوزات بعد</p>
              <p className="text-muted-foreground mt-2">
                {user.role === 'customer' ? 'تصفح العاملات وابدأ بحجز موعدك الأول' : 'ستظهر هنا حجوزات العملاء لعاملاتك'}
              </p>
            </div>
          ) : (
            <div className="space-y-4">
              {myBookings.sort((a,b) => new Date(b.date).getTime() - new Date(a.date).getTime()).map(booking => {
                const cleaner = cleaners.find(c => c.id === booking.cleanerId);
                
                return (
                  <div key={booking.id} className="bg-card border rounded-2xl p-6 flex flex-col md:flex-row justify-between items-start md:items-center gap-6 shadow-sm hover:border-primary/50 transition-colors">
                    <div className="flex-1 space-y-3">
                      <div className="flex items-center gap-3">
                        <StatusBadge status={booking.status} />
                        <span className="text-sm font-bold text-muted-foreground">رقم الحجز: #{booking.id}</span>
                      </div>
                      
                      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mt-2">
                        <div className="flex items-center gap-2">
                          <UserCircle className="w-5 h-5 text-primary" />
                          <span className="font-medium">{user.role === 'customer' ? `العاملة: ${cleaner?.name || '...'}` : `العميل: (ID ${booking.customerId})`}</span>
                        </div>
                        <div className="flex items-center gap-2">
                          <Calendar className="w-5 h-5 text-primary" />
                          <span className="font-medium">{booking.date} | {booking.timeSlot}</span>
                        </div>
                        <div className="flex items-center gap-2">
                          <MapPin className="w-5 h-5 text-primary" />
                          <span className="font-medium text-sm truncate">{booking.address}</span>
                        </div>
                        <div className="flex items-center gap-2">
                          <DollarSign className="w-5 h-5 text-primary" />
                          <span className="font-bold text-lg">{booking.totalPrice} ريال</span>
                        </div>
                      </div>
                    </div>

                    {/* Actions based on role and status */}
                    <div className="flex flex-row md:flex-col gap-2 w-full md:w-auto">
                      {user.role === 'company' && booking.status === 'pending' && (
                        <>
                          <Button 
                            className="bg-blue-600 hover:bg-blue-700 flex-1 md:flex-none"
                            onClick={() => updateStatus.mutate({ id: booking.id, status: 'confirmed' })}
                            disabled={updateStatus.isPending}
                          >
                            <CheckCircle2 className="w-4 h-4 ml-2" /> تأكيد
                          </Button>
                          <Button 
                            variant="destructive"
                            className="flex-1 md:flex-none"
                            onClick={() => updateStatus.mutate({ id: booking.id, status: 'cancelled' })}
                            disabled={updateStatus.isPending}
                          >
                            <XCircle className="w-4 h-4 ml-2" /> رفض
                          </Button>
                        </>
                      )}

                      {user.role === 'company' && booking.status === 'confirmed' && (
                        <Button 
                          className="bg-green-600 hover:bg-green-700 w-full"
                          onClick={() => updateStatus.mutate({ id: booking.id, status: 'completed' })}
                          disabled={updateStatus.isPending}
                        >
                          <CheckCircle2 className="w-4 h-4 ml-2" /> تحديد كمكتمل
                        </Button>
                      )}

                      {user.role === 'customer' && booking.status === 'pending' && (
                        <Button 
                          variant="destructive"
                          className="w-full"
                          onClick={() => updateStatus.mutate({ id: booking.id, status: 'cancelled' })}
                          disabled={updateStatus.isPending}
                        >
                          إلغاء الحجز
                        </Button>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>
    </Layout>
  );
}
