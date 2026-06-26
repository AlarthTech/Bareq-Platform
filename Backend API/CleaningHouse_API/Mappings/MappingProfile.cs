using AutoMapper;
using CleaningHouse_API.DTOs.Admin;
using CleaningHouse_API.DTOs.Common;
using CleaningHouse_API.DTOs.Companies;
using CleaningHouse_API.DTOs.Customers;
using CleaningHouse_API.Models.Admin;
using CleaningHouse_API.Models.Common;
using CleaningHouse_API.Models.Companies;
using CleaningHouse_API.Models.Customers;

namespace CleaningHouse_API.Mappings;

public class MappingProfile : Profile
{
    public MappingProfile()
    {
        CreateMap<Notification, NotificationDTO>();

        CreateMap<AppUser, AppUserDTO>()
            .ForMember(d => d.UserTypeName, o => o.MapFrom(s => s.UserType != null ? s.UserType.Name : null));

        CreateMap<UpdateAppUserDTO, AppUser>()
            .ForMember(d => d.PasswordHash, o => o.Ignore())
            .ForMember(d => d.Id, o => o.Ignore())
            .ForMember(d => d.UserTypeId, o => o.Ignore())
            .ForMember(d => d.CreatedAt, o => o.Ignore())
            .ForAllMembers(o => o.Condition((_, _, srcMember) => srcMember != null));

        CreateMap<UserType, UserTypeDTO>()
            .ForMember(d => d.Description, o => o.Ignore());

        CreateMap<UserLocation, UserLocationDTO>();
        CreateMap<CreateUserLocationDTO, UserLocation>();
        CreateMap<UpdateUserLocationDTO, UserLocation>()
            .ForAllMembers(o => o.Condition((_, _, srcMember) => srcMember != null));

        CreateMap<Report, ReportDTO>()
            .ForMember(d => d.UserName, o => o.MapFrom(s => s.AppUser != null ? s.AppUser.FullName : null))
            .ForMember(d => d.WorkerName, o => o.MapFrom(s => s.Worker != null ? s.Worker.FullName : null))
            .ForMember(d => d.CompanyName, o => o.MapFrom(s => s.Company != null ? s.Company.Name : null))
            .ForMember(d => d.TargetTypeName, o => o.Ignore())
            .ForMember(d => d.StatusName, o => o.Ignore());

        CreateMap<Nationality, NationalityDTO>()
            .ForMember(d => d.Code, o => o.Ignore());
        CreateMap<CreateNationalityDTO, Nationality>();
        CreateMap<UpdateNationalityDTO, Nationality>()
            .ForAllMembers(o => o.Condition((_, _, srcMember) => srcMember != null));

        CreateMap<Language, LanguageDTO>()
            .ForMember(d => d.Code, o => o.Ignore());
        CreateMap<CreateLanguageDTO, Language>();
        CreateMap<UpdateLanguageDTO, Language>()
            .ForAllMembers(o => o.Condition((_, _, srcMember) => srcMember != null));

        CreateMap<Company, CompanyDTO>()
            .ForMember(d => d.OwnerUserName, o => o.MapFrom(s => s.OwnerAppUser != null ? s.OwnerAppUser.FullName : null))
            .ForMember(d => d.CityName, o => o.MapFrom(s => s.City != null ? s.City.Name : null));
        CreateMap<CreateCompanyDTO, Company>();
        CreateMap<UpdateCompanyDTO, Company>()
            .ForAllMembers(o => o.Condition((_, _, srcMember) => srcMember != null));

        CreateMap<City, CityDTO>()
            .ForMember(d => d.Code, o => o.Ignore());
        CreateMap<CreateCityDTO, City>();
        CreateMap<UpdateCityDTO, City>()
            .ForAllMembers(o => o.Condition((_, _, srcMember) => srcMember != null));

        CreateMap<Review, ReviewDTO>()
            .ForMember(d => d.UserName, o => o.MapFrom(s => s.AppUser != null ? s.AppUser.FullName : null))
            .ForMember(d => d.WorkerName, o => o.MapFrom(s => s.Worker != null ? s.Worker.FullName : null));
        CreateMap<UpdateReviewDTO, Review>()
            .ForAllMembers(o => o.Condition((_, _, srcMember) => srcMember != null));

        CreateMap<WorkType, WorkTypeDTO>()
            .ForMember(d => d.CompanyName, o => o.MapFrom(s => s.Company != null ? s.Company.Name : null))
            .ForMember(d => d.IsMonthly, o => o.MapFrom(s => s.MonthlyPrice != null));
        CreateMap<CreateWorkTypeDTO, WorkType>()
            .ForMember(d => d.MonthlyPrice, o => o.MapFrom(s =>
                s.IsMonthly ? s.MonthlyPrice ?? s.Price : (decimal?)null))
            .ForMember(d => d.StartTime, o => o.MapFrom(s =>
                string.IsNullOrWhiteSpace(s.StartTime) ? "00:00" : s.StartTime!.Trim()))
            .ForMember(d => d.EndTime, o => o.MapFrom(s =>
                string.IsNullOrWhiteSpace(s.EndTime) ? "00:00" : s.EndTime!.Trim()));
        CreateMap<UpdateWorkTypeDTO, WorkType>()
            .ForAllMembers(o => o.Condition((_, _, srcMember) => srcMember != null));

        CreateMap<Worker, WorkerDTO>()
            .ForMember(d => d.CompanyName, o => o.MapFrom(s => s.Company != null ? s.Company.Name : null))
            .ForMember(d => d.NationalityName, o => o.MapFrom(s => s.Nationality != null ? s.Nationality.Name : null));
        CreateMap<CreateWorkerDTO, Worker>();
        CreateMap<UpdateWorkerDTO, Worker>()
            .ForAllMembers(o => o.Condition((_, _, srcMember) => srcMember != null));

        CreateMap<WorkerWorkType, WorkerWorkTypeDTO>()
            .ForMember(d => d.WorkerName, o => o.MapFrom(s => s.Worker != null ? s.Worker.FullName : null))
            .ForMember(d => d.WorkTypeName, o => o.MapFrom(s => s.WorkType != null ? s.WorkType.Name : null))
            .ForMember(d => d.StartTime, o => o.MapFrom(s => s.WorkType != null ? s.WorkType.StartTime : string.Empty))
            .ForMember(d => d.EndTime, o => o.MapFrom(s => s.WorkType != null ? s.WorkType.EndTime : string.Empty))
            .ForMember(d => d.IsOvernight, o => o.MapFrom(s => s.WorkType != null && s.WorkType.IsOvernight))
            .ForMember(d => d.Price, o => o.MapFrom(s => s.WorkType != null ? s.WorkType.Price : 0))
            .ForMember(d => d.MonthlyPrice, o => o.MapFrom(s => s.WorkType != null ? s.WorkType.MonthlyPrice : null));

        CreateMap<Favorite, FavoriteDTO>()
            .ForMember(d => d.UserName, o => o.MapFrom(s => s.AppUser != null ? s.AppUser.FullName : null))
            .ForMember(d => d.WorkerName, o => o.MapFrom(s => s.Worker != null ? s.Worker.FullName : null))
            .ForMember(d => d.WorkerProfileImage, o => o.MapFrom(s => s.Worker != null ? s.Worker.ProfileImage : null))
            .ForMember(d => d.CompanyId, o => o.MapFrom(s => s.Worker != null ? (int?)s.Worker.CompanyId : null))
            .ForMember(d => d.CompanyName, o => o.MapFrom(s => s.Worker != null && s.Worker.Company != null ? s.Worker.Company.Name : null));

        CreateMap<CleaningService, CleaningServiceDTO>()
            .ForMember(d => d.Description, o => o.Ignore());
        CreateMap<CreateCleaningServiceDTO, CleaningService>()
            .ForMember(d => d.Id, o => o.Ignore());
        CreateMap<UpdateCleaningServiceDTO, CleaningService>()
            .ForAllMembers(o => o.Condition((_, _, srcMember) => srcMember != null));
    }
}
